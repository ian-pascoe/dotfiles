// rex-plannotator runs plannotator-tui's Herdr pane inside Rex. Two seams:
// - as HERDR_BIN_PATH, the `herdr` commands plannotator-tui runs, judged by
//   the `rex` calls they make;
// - `review`, judged by the environment it starts plannotator-tui with.
// A fake `rex` (via REX_BIN_DIR) logs its calls and answers from fixtures; a
// fake `plannotator-tui` (first on PATH) records its argv and environment.
import { spawnSync } from "node:child_process";
import {
  chmodSync,
  mkdirSync,
  mkdtempSync,
  readFileSync,
  realpathSync,
  rmSync,
  writeFileSync,
} from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { afterEach, describe, expect, test } from "vite-plus/test";

const script = join(dirname(fileURLToPath(import.meta.url)), "executable_rex-plannotator");

const FAKE_REX = `#!/usr/bin/env node
const fs = require("fs"), path = require("path");
const argv = process.argv.slice(2);
let stdin = "";
try { stdin = fs.readFileSync(0, "utf8"); } catch {}
fs.appendFileSync(path.join(__dirname, "calls.jsonl"), JSON.stringify({ argv, stdin }) + "\\n");
if (["send", "send-key", "do"].includes(argv[0])) process.exit(0);
const key = argv[0] === "block" ? argv[argv.length - 1] : argv[0];
const fixture = path.join(__dirname, "fixtures", key);
if (!fs.existsSync(fixture)) { process.stderr.write("block not found\\n"); process.exit(1); }
process.stdout.write(fs.readFileSync(fixture, "utf8"));
`;

const FAKE_TUI = `#!/usr/bin/env node
const fs = require("fs"), path = require("path");
const env = Object.fromEntries(Object.entries(process.env).filter(([k]) => /^(HERDR|PLANNOTATOR_TUI)_/.test(k)));
fs.writeFileSync(path.join(__dirname, "tui.json"), JSON.stringify({ argv: process.argv.slice(2), env, cwd: process.cwd() }));
`;

type Call = { argv: string[]; stdin: string };

const BLOCK = "block:01aa";

// A pane running pi: Rex's program status and process info, and its modes.
const piPane = {
  program_status: JSON.stringify({
    records: [{ state: "idle", app: "pi", owner: { pid: 4242, name: "pi" } }],
  }),
  process: JSON.stringify({
    foreground: { pid: 4242, name: "pi", cwd: "/work/project" },
  }),
  modes: JSON.stringify({ modes: [{ name: "bracketed_paste", number: 2004, set: true }] }),
};

// A pane at a shell prompt.
const shellPane = {
  program_status: JSON.stringify({ records: [] }),
  process: JSON.stringify({ foreground: { pid: 99, name: "zsh", cwd: "/work/project" } }),
  modes: piPane.modes,
};

// A pane running an agent that reports Rex's program status, but whose
// transcripts plannotator-tui can't read.
const aiderPane = {
  program_status: JSON.stringify({
    records: [{ state: "idle", app: "aider", owner: { pid: 5151, name: "python3" } }],
  }),
  process: JSON.stringify({ foreground: { pid: 5151, name: "python3", cwd: "/work/project" } }),
  modes: piPane.modes,
};

const temporary: string[] = [];
afterEach(() => {
  for (const dir of temporary.splice(0)) rmSync(dir, { recursive: true, force: true });
});

function tempDir(prefix: string): string {
  const dir = realpathSync(mkdtempSync(join(tmpdir(), prefix)));
  temporary.push(dir);
  return dir;
}

function setup(fixtures: Record<string, string> = {}) {
  const dir = tempDir("rex-plannotator-");
  mkdirSync(join(dir, "fixtures"));
  for (const [name, content] of Object.entries(fixtures)) {
    writeFileSync(join(dir, "fixtures", name), content);
  }
  for (const [name, content] of [
    ["rex", FAKE_REX],
    ["plannotator-tui", FAKE_TUI],
  ]) {
    writeFileSync(join(dir, name), content);
    chmodSync(join(dir, name), 0o755);
  }
  const run = (args: string[], options: { cwd?: string } = {}) =>
    spawnSync("bash", [script, ...args], {
      cwd: options.cwd ?? dir,
      encoding: "utf8",
      input: "",
      env: {
        PATH: `${dir}:${process.env.PATH}`,
        HOME: process.env.HOME,
        REX_BIN_DIR: dir,
      },
    });
  const calls = (): Call[] => {
    try {
      return readFileSync(join(dir, "calls.jsonl"), "utf8")
        .trim()
        .split("\n")
        .map((line) => JSON.parse(line));
    } catch {
      return [];
    }
  };
  const tui = () => JSON.parse(readFileSync(join(dir, "tui.json"), "utf8"));
  return { dir, run, calls, tui };
}

describe("as herdr: pane get", () => {
  test("names the agent in the pane, where plannotator-tui reads it", () => {
    const { run } = setup(piPane);
    const result = run(["pane", "get", BLOCK]);
    expect(result.status, result.stderr).toBe(0);
    expect(JSON.parse(result.stdout).result.pane.agent).toBe("pi");
  });

  test("names an agent that doesn't report status by its process", () => {
    const { run } = setup({
      program_status: JSON.stringify({ records: [] }),
      process: JSON.stringify({ foreground: { pid: 7, name: "claude", cwd: "/w" } }),
    });
    expect(JSON.parse(run(["pane", "get", BLOCK]).stdout).result.pane.agent).toBe("claude");
  });

  test("names an agent Rex reports, even one whose transcripts plannotator-tui can't read", () => {
    const { run } = setup(aiderPane);
    expect(JSON.parse(run(["pane", "get", BLOCK]).stdout).result.pane.agent).toBe("aider");
  });

  test("reports no agent for a shell", () => {
    const { run } = setup(shellPane);
    const result = run(["pane", "get", BLOCK]);
    expect(result.status, result.stderr).toBe(0);
    expect(JSON.parse(result.stdout).result.pane.agent).toBeUndefined();
  });
});

describe("review", () => {
  const project = () => {
    const dir = tempDir("rex-plannotator-project-");
    writeFileSync(join(dir, "plan.md"), "# Plan\n");
    return dir;
  };

  test("reviews the folder it runs in, sending feedback to the agent in the target pane", () => {
    const { run, tui } = setup(piPane);
    const cwd = project();
    const result = run(["review", "--target", BLOCK], { cwd });
    expect(result.status, result.stderr).toBe(0);
    expect(tui()).toEqual({
      argv: ["herdr", "pane"],
      cwd,
      env: {
        HERDR_ENV: "1",
        HERDR_BIN_PATH: script,
        PLANNOTATOR_TUI_FILE: cwd,
        PLANNOTATOR_TUI_DELIVER_TO: BLOCK,
        PLANNOTATOR_TUI_DELIVER_AGENT: "pi",
      },
    });
  });

  test("sends feedback to the clipboard when no agent runs in the target pane", () => {
    const { run, tui } = setup(shellPane);
    const result = run(["review", "--target", BLOCK], { cwd: project() });
    expect(result.status, result.stderr).toBe(0);
    expect(tui().env).not.toHaveProperty("PLANNOTATOR_TUI_DELIVER_TO");
  });

  test("reviews --file, gated, publishing the decision to --result-file", () => {
    const { run, tui } = setup(piPane);
    const cwd = project();
    const args = ["--target", BLOCK, "--file", "plan.md", "--gate", "--result-file", "out.json"];
    const result = run(["review", ...args], { cwd });
    expect(result.status, result.stderr).toBe(0);
    expect(tui().env).toMatchObject({
      PLANNOTATOR_TUI_FILE: join(cwd, "plan.md"),
      PLANNOTATOR_TUI_GATE: "1",
      PLANNOTATOR_TUI_RESULT_FILE: join(cwd, "out.json"),
      PLANNOTATOR_TUI_DELIVER_TO: BLOCK,
    });
  });

  test("--last reviews the agent's replies, found by its process and directory", () => {
    const { run, tui } = setup(piPane);
    const result = run(["review", "--target", BLOCK, "--last"], { cwd: project() });
    expect(result.status, result.stderr).toBe(0);
    expect(tui().env).toEqual({
      HERDR_ENV: "1",
      HERDR_BIN_PATH: script,
      PLANNOTATOR_TUI_MESSAGE_PID: "4242",
      PLANNOTATOR_TUI_HOST: "pi",
      PLANNOTATOR_TUI_CWD: "/work/project",
      PLANNOTATOR_TUI_DELIVER_TO: BLOCK,
      PLANNOTATOR_TUI_DELIVER_AGENT: "pi",
    });
  });

  test("--last names an agent plannotator-tui can't read, so it falls back to the screen", () => {
    const { run, tui } = setup(aiderPane);
    run(["review", "--target", BLOCK, "--last"], { cwd: project() });
    expect(tui().env).toMatchObject({
      PLANNOTATOR_TUI_HOST: "aider",
      PLANNOTATOR_TUI_MESSAGE_PID: "5151",
      PLANNOTATOR_TUI_DELIVER_TO: BLOCK,
    });
  });

  test("--deliver-to sends feedback to that pane, agent or not", () => {
    const { run, tui } = setup(shellPane);
    const cwd = project();
    const args = ["--target", BLOCK, "--deliver-to", "block:02bb", "--file", "plan.md"];
    const result = run(["review", ...args], { cwd });
    expect(result.status, result.stderr).toBe(0);
    expect(tui().env.PLANNOTATOR_TUI_DELIVER_TO).toBe("block:02bb");
  });

  test("refuses a target pane that doesn't exist, without starting plannotator-tui", () => {
    const { run, dir } = setup();
    const result = run(["review", "--target", BLOCK], { cwd: project() });
    expect(result.status).not.toBe(0);
    expect(result.stderr).toMatch(/not found/i);
    expect(() => readFileSync(join(dir, "tui.json"))).toThrow();
  });

  test("refuses a flag missing its value", () => {
    const { run, dir } = setup(piPane);
    const result = run(["review", "--target", BLOCK, "--file"], { cwd: project() });
    expect(result.status).not.toBe(0);
    expect(result.stderr).toMatch(/--file needs a value/);
    expect(() => readFileSync(join(dir, "tui.json"))).toThrow();
  });

  test("--newest opens the newest reply without the picker", () => {
    const { run, tui } = setup(piPane);
    run(["review", "--target", BLOCK, "--last", "--newest"], { cwd: project() });
    expect(tui().env.PLANNOTATOR_TUI_NEWEST).toBe("1");
  });

  test("--last refuses a pane with no agent, without starting plannotator-tui", () => {
    const { run, dir } = setup(shellPane);
    const result = run(["review", "--target", BLOCK, "--last"], { cwd: project() });
    expect(result.status).not.toBe(0);
    expect(result.stderr).toMatch(/no agent/i);
    expect(() => readFileSync(join(dir, "tui.json"))).toThrow();
  });

  test("--terminal reviews the target pane's recent output", () => {
    const { run, tui } = setup(shellPane);
    const result = run(["review", "--target", BLOCK, "--terminal", "--lines", "50"], {
      cwd: project(),
    });
    expect(result.status, result.stderr).toBe(0);
    expect(tui().env).toEqual({
      HERDR_ENV: "1",
      HERDR_BIN_PATH: script,
      PLANNOTATOR_TUI_TERMINAL_PANE: BLOCK,
      PLANNOTATOR_TUI_TERMINAL_LINES: "50",
    });
  });
});

describe("as herdr: pane read and agent read", () => {
  const capture = "one\ntwo\nthree\nfour\n";

  test("pane read gives the last --lines lines of the unwrapped capture", () => {
    const { run, calls } = setup({ ...piPane, capture });
    const args = ["--source", "recent-unwrapped", "--lines", "2", "--format", "text"];
    const result = run(["pane", "read", BLOCK, ...args]);
    expect(result.status, result.stderr).toBe(0);
    expect(result.stdout).toBe("three\nfour\n");
    expect(calls().find((c) => c.argv[0] === "capture")?.argv).toEqual([
      "capture",
      "-b",
      BLOCK,
      "--trim",
      "--unwrap",
    ]);
  });

  test("agent read gives the recent output too", () => {
    const { run } = setup({ ...piPane, capture });
    const args = ["--source", "recent-unwrapped", "--format", "text"];
    expect(run(["agent", "read", BLOCK, ...args]).stdout).toBe(capture);
  });

  test("fails for a pane that doesn't exist", () => {
    const { run } = setup();
    expect(run(["pane", "read", BLOCK, "--lines", "2"]).status).not.toBe(0);
  });
});

describe("as herdr: agent prompt", () => {
  test("pastes the feedback into the agent's pane, then presses Enter", () => {
    const { run, calls } = setup(piPane);
    const result = run(["agent", "prompt", BLOCK, "## 1. Feedback\n> fix it"]);
    expect(result.status, result.stderr).toBe(0);
    const writes = calls().filter((c) => c.argv[0] === "send" || c.argv[0] === "send-key");
    expect(writes).toEqual([
      { argv: ["send", "-b", BLOCK], stdin: "\x1b[200~## 1. Feedback\n> fix it\x1b[201~" },
      { argv: ["send-key", "-b", BLOCK, "enter"], stdin: "" },
    ]);
  });

  test("strips control characters, so quoted terminal text can't end the paste early", () => {
    const { run, calls } = setup(piPane);
    run(["agent", "prompt", BLOCK, "before\x1b[201~\r\x03after\tend"]);
    const paste = calls().find((c) => c.argv[0] === "send");
    expect(paste?.stdin).toBe("\x1b[200~before[201~after\tend\x1b[201~");
  });

  test("refuses while the agent waits at a prompt, typing nothing", () => {
    const { run, calls } = setup({
      ...piPane,
      program_status: JSON.stringify({
        records: [
          { state: "blocked", kind: "permission", app: "pi", owner: { pid: 4242, name: "pi" } },
        ],
      }),
    });
    const result = run(["agent", "prompt", BLOCK, "feedback"]);
    expect(result.status).not.toBe(0);
    expect(JSON.parse(result.stderr).error.code).toBe("agent_blocked");
    expect(calls().filter((c) => c.argv[0].startsWith("send"))).toEqual([]);
  });

  test("delivers to an agent Rex reports, whatever its name", () => {
    const { run, calls } = setup(aiderPane);
    const result = run(["agent", "prompt", BLOCK, "feedback"]);
    expect(result.status, result.stderr).toBe(0);
    expect(calls().find((c) => c.argv[0] === "send")?.stdin).toBe("\x1b[200~feedback\x1b[201~");
  });

  test("types the feedback unwrapped when the agent hasn't turned on bracketed paste", () => {
    const { run, calls } = setup({
      ...piPane,
      modes: JSON.stringify({ modes: [{ name: "bracketed_paste", number: 2004, set: false }] }),
    });
    run(["agent", "prompt", BLOCK, "feedback"]);
    expect(calls().find((c) => c.argv[0] === "send")?.stdin).toBe("feedback");
  });

  test("reports a pane that doesn't exist", () => {
    const { run } = setup();
    const result = run(["agent", "prompt", BLOCK, "feedback"]);
    expect(result.status).not.toBe(0);
    expect(JSON.parse(result.stderr).error.code).toBe("pane_not_found");
  });

  test("refuses a pane with no agent in it, typing nothing", () => {
    const { run, calls } = setup(shellPane);
    const result = run(["agent", "prompt", BLOCK, "feedback"]);
    expect(result.status).not.toBe(0);
    expect(JSON.parse(result.stderr).error.code).toBe("agent_not_found");
    expect(calls().filter((c) => c.argv[0].startsWith("send"))).toEqual([]);
  });
});
