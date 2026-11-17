// herdr-app-plannotator runs plannotator-tui's Herdr pane inside the Herdr
// desktop app, whose terminals herdr-core (`hc`) runs. Three seams:
// - as HERDR_BIN_PATH, the `herdr` commands plannotator-tui runs, judged by
//   the `hc` calls they make;
// - `review`, judged by the environment it starts plannotator-tui with;
// - `open`, judged by the herdr-app-popup command it runs.
// A fake `hc` (via HC_BIN) logs its calls and answers from fixtures; a fake
// `plannotator-tui` and `herdr-app-popup` (first on PATH) record their argv.
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

const script = join(dirname(fileURLToPath(import.meta.url)), "executable_herdr-app-plannotator");

// Answers `get` and `read` from fixtures/<command>, like hc: JSON on stdout,
// an error envelope on stderr. `send` succeeds unless fixtures/send-error
// holds the error it fails with.
const FAKE_HC = `#!/usr/bin/env node
const fs = require("fs"), path = require("path");
const argv = process.argv.slice(2);
fs.appendFileSync(path.join(__dirname, "calls.jsonl"), JSON.stringify({ argv }) + "\\n");
const fixture = (name) => path.join(__dirname, "fixtures", name);
if (argv[0] === "send") {
  if (!fs.existsSync(fixture("send-error"))) process.exit(0);
  process.stderr.write(fs.readFileSync(fixture("send-error"), "utf8"));
  process.exit(3);
}
if (!fs.existsSync(fixture(argv[0]))) {
  process.stderr.write(JSON.stringify({ error: { kind: "not_found", message: "no terminal" } }));
  process.exit(3);
}
process.stdout.write(fs.readFileSync(fixture(argv[0]), "utf8"));
`;

const FAKE_TUI = `#!/usr/bin/env node
const fs = require("fs"), path = require("path");
const env = Object.fromEntries(Object.entries(process.env).filter(([k]) => /^(HERDR|PLANNOTATOR_TUI)_/.test(k)));
fs.writeFileSync(path.join(__dirname, "tui.json"), JSON.stringify({ argv: process.argv.slice(2), env, cwd: process.cwd() }));
`;

const FAKE_POPUP = `#!/usr/bin/env node
const fs = require("fs"), path = require("path");
fs.writeFileSync(path.join(__dirname, "popup.json"), JSON.stringify(process.argv.slice(2)));
`;

const TERMINAL = "t7";

// What `hc get` says of a terminal: its foreground process and 7501 status.
function terminal(fields: Record<string, unknown>): string {
  return JSON.stringify({
    address: TERMINAL,
    cwd: "/work",
    pid: 100,
    state: "live",
    status: null,
    records: {},
    ...fields,
  });
}

// A terminal running pi, which reports its status.
const piTerminal = {
  get: terminal({
    foreground: { argv: ["pi"], cwd: "/work/project", name: "pi", pid: 4242 },
    status: { app: "pi", state: "idle" },
  }),
};

// A terminal at a shell prompt.
const shellTerminal = {
  get: terminal({ foreground: { argv: ["zsh"], cwd: "/work/project", name: "zsh", pid: 99 } }),
};

// A terminal running an agent that reports its status, but whose transcripts
// plannotator-tui can't read.
const aiderTerminal = {
  get: terminal({
    foreground: { argv: ["python3", "aider"], cwd: "/work/project", name: "python3", pid: 5151 },
    status: { app: "aider", state: "idle" },
  }),
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
  const dir = tempDir("herdr-app-plannotator-");
  mkdirSync(join(dir, "fixtures"));
  for (const [name, content] of Object.entries(fixtures)) {
    writeFileSync(join(dir, "fixtures", name), content);
  }
  for (const [name, content] of [
    ["hc", FAKE_HC],
    ["plannotator-tui", FAKE_TUI],
    ["herdr-app-popup", FAKE_POPUP],
  ]) {
    writeFileSync(join(dir, name), content);
    chmodSync(join(dir, name), 0o755);
  }
  const run = (args: string[], options: { cwd?: string; env?: Record<string, string> } = {}) =>
    spawnSync("bash", [script, ...args], {
      cwd: options.cwd ?? dir,
      encoding: "utf8",
      input: "",
      env: {
        PATH: `${dir}:${process.env.PATH}`,
        HOME: process.env.HOME,
        HC_BIN: join(dir, "hc"),
        ...options.env,
      },
    });
  const calls = (): string[][] => {
    try {
      return readFileSync(join(dir, "calls.jsonl"), "utf8")
        .trim()
        .split("\n")
        .map((line) => JSON.parse(line).argv);
    } catch {
      return [];
    }
  };
  const tui = () => JSON.parse(readFileSync(join(dir, "tui.json"), "utf8"));
  const popup = () => JSON.parse(readFileSync(join(dir, "popup.json"), "utf8"));
  return { dir, run, calls, tui, popup };
}

describe("as herdr: pane get", () => {
  test("names the agent in the terminal, where plannotator-tui reads it", () => {
    const { run } = setup(piTerminal);
    const result = run(["pane", "get", TERMINAL]);
    expect(result.status, result.stderr).toBe(0);
    expect(JSON.parse(result.stdout)).toEqual({
      result: { pane: { pane_id: TERMINAL, agent: "pi" } },
    });
  });

  test("names an agent that doesn't report status by its process", () => {
    const { run } = setup({
      get: terminal({ foreground: { argv: ["claude"], cwd: "/w", name: "claude", pid: 7 } }),
    });
    expect(JSON.parse(run(["pane", "get", TERMINAL]).stdout).result.pane.agent).toBe("claude");
  });

  test("names an agent that reports status, even one whose transcripts plannotator-tui can't read", () => {
    const { run } = setup(aiderTerminal);
    expect(JSON.parse(run(["pane", "get", TERMINAL]).stdout).result.pane.agent).toBe("aider");
  });

  test("reports no agent for a shell", () => {
    const { run } = setup(shellTerminal);
    const result = run(["pane", "get", TERMINAL]);
    expect(result.status, result.stderr).toBe(0);
    expect(JSON.parse(result.stdout).result.pane.agent).toBeUndefined();
  });

  test("reports a terminal that doesn't exist", () => {
    const { run } = setup();
    const result = run(["pane", "get", TERMINAL]);
    expect(result.status).not.toBe(0);
    expect(JSON.parse(result.stderr).error.code).toBe("pane_not_found");
  });
});

describe("review", () => {
  const project = () => {
    const dir = tempDir("herdr-app-plannotator-project-");
    writeFileSync(join(dir, "plan.md"), "# Plan\n");
    return dir;
  };

  test("reviews the folder it runs in, sending feedback to the agent in the target terminal", () => {
    const { run, tui, calls } = setup(piTerminal);
    const cwd = project();
    const result = run(["review", "--target", TERMINAL], { cwd });
    expect(result.status, result.stderr).toBe(0);
    expect(calls()).toEqual([["get", TERMINAL, "--json"]]);
    expect(tui()).toEqual({
      argv: ["herdr", "pane"],
      cwd,
      env: {
        HERDR_ENV: "1",
        HERDR_BIN_PATH: script,
        PLANNOTATOR_TUI_FILE: cwd,
        PLANNOTATOR_TUI_DELIVER_TO: TERMINAL,
        PLANNOTATOR_TUI_DELIVER_AGENT: "pi",
      },
    });
  });

  test("sends feedback to the clipboard when no agent runs in the target terminal", () => {
    const { run, tui } = setup(shellTerminal);
    const result = run(["review", "--target", TERMINAL], { cwd: project() });
    expect(result.status, result.stderr).toBe(0);
    expect(tui().env).not.toHaveProperty("PLANNOTATOR_TUI_DELIVER_TO");
  });

  test("reviews --file, gated, publishing the decision to --result-file", () => {
    const { run, tui } = setup(piTerminal);
    const cwd = project();
    const args = ["--target", TERMINAL, "--file", "plan.md", "--gate", "--result-file", "out.json"];
    const result = run(["review", ...args], { cwd });
    expect(result.status, result.stderr).toBe(0);
    expect(tui().env).toMatchObject({
      PLANNOTATOR_TUI_FILE: join(cwd, "plan.md"),
      PLANNOTATOR_TUI_GATE: "1",
      PLANNOTATOR_TUI_RESULT_FILE: join(cwd, "out.json"),
      PLANNOTATOR_TUI_DELIVER_TO: TERMINAL,
    });
  });

  test("--last reviews the agent's replies, found by its process and directory", () => {
    const { run, tui } = setup(piTerminal);
    const result = run(["review", "--target", TERMINAL, "--last"], { cwd: project() });
    expect(result.status, result.stderr).toBe(0);
    expect(tui().env).toEqual({
      HERDR_ENV: "1",
      HERDR_BIN_PATH: script,
      PLANNOTATOR_TUI_MESSAGE_PID: "4242",
      PLANNOTATOR_TUI_HOST: "pi",
      PLANNOTATOR_TUI_CWD: "/work/project",
      PLANNOTATOR_TUI_DELIVER_TO: TERMINAL,
      PLANNOTATOR_TUI_DELIVER_AGENT: "pi",
    });
  });

  test("--last names an agent plannotator-tui can't read, so it falls back to the screen", () => {
    const { run, tui } = setup(aiderTerminal);
    run(["review", "--target", TERMINAL, "--last"], { cwd: project() });
    expect(tui().env).toMatchObject({
      PLANNOTATOR_TUI_HOST: "aider",
      PLANNOTATOR_TUI_MESSAGE_PID: "5151",
      PLANNOTATOR_TUI_DELIVER_TO: TERMINAL,
    });
  });

  test("--deliver-to sends feedback to that terminal, agent or not", () => {
    const { run, tui } = setup(shellTerminal);
    const cwd = project();
    const args = ["--target", TERMINAL, "--deliver-to", "t9", "--file", "plan.md"];
    const result = run(["review", ...args], { cwd });
    expect(result.status, result.stderr).toBe(0);
    expect(tui().env.PLANNOTATOR_TUI_DELIVER_TO).toBe("t9");
  });

  test("refuses a target terminal that doesn't exist, without starting plannotator-tui", () => {
    const { run, dir } = setup();
    const result = run(["review", "--target", TERMINAL], { cwd: project() });
    expect(result.status).not.toBe(0);
    expect(result.stderr).toMatch(/not found/i);
    expect(() => readFileSync(join(dir, "tui.json"))).toThrow();
  });

  test("refuses a flag missing its value", () => {
    const { run, dir } = setup(piTerminal);
    const result = run(["review", "--target", TERMINAL, "--file"], { cwd: project() });
    expect(result.status).not.toBe(0);
    expect(result.stderr).toMatch(/--file needs a value/);
    expect(() => readFileSync(join(dir, "tui.json"))).toThrow();
  });

  test("--newest opens the newest reply without the picker", () => {
    const { run, tui } = setup(piTerminal);
    run(["review", "--target", TERMINAL, "--last", "--newest"], { cwd: project() });
    expect(tui().env.PLANNOTATOR_TUI_NEWEST).toBe("1");
  });

  test("--last refuses a terminal with no agent, without starting plannotator-tui", () => {
    const { run, dir } = setup(shellTerminal);
    const result = run(["review", "--target", TERMINAL, "--last"], { cwd: project() });
    expect(result.status).not.toBe(0);
    expect(result.stderr).toMatch(/no agent/i);
    expect(() => readFileSync(join(dir, "tui.json"))).toThrow();
  });

  test("--terminal reviews the target terminal's recent output", () => {
    const { run, tui } = setup(shellTerminal);
    const result = run(["review", "--target", TERMINAL, "--terminal", "--lines", "50"], {
      cwd: project(),
    });
    expect(result.status, result.stderr).toBe(0);
    expect(tui().env).toEqual({
      HERDR_ENV: "1",
      HERDR_BIN_PATH: script,
      PLANNOTATOR_TUI_TERMINAL_PANE: TERMINAL,
      PLANNOTATOR_TUI_TERMINAL_LINES: "50",
    });
  });
});

describe("open", () => {
  const project = () => {
    const dir = tempDir("herdr-app-plannotator-project-");
    mkdirSync(join(dir, "docs"));
    writeFileSync(join(dir, "docs", "plan.md"), "# Plan\n");
    return dir;
  };

  test("reviews the file in a popup, the feedback going back to the calling terminal", () => {
    const { run, popup } = setup(piTerminal);
    const cwd = project();
    const result = run(["open", "docs/plan.md"], { cwd, env: { HC_TERMINAL_ID: "t2" } });
    expect(result.status, result.stderr).toBe(0);
    expect(popup()).toEqual([
      "--cwd",
      join(cwd, "docs"),
      "--",
      script,
      "review",
      "--target",
      "t2",
      "--deliver-to",
      "t2",
      "--file",
      join(cwd, "docs", "plan.md"),
    ]);
  });

  test("passes --gate and an absolute --result-file on to review", () => {
    const { run, popup } = setup(piTerminal);
    const cwd = project();
    const args = ["open", "docs/plan.md", "--gate", "--result-file", "out.json"];
    const result = run(args, { cwd, env: { HC_TERMINAL_ID: "t2" } });
    expect(result.status, result.stderr).toBe(0);
    expect(popup().slice(-3)).toEqual(["--gate", "--result-file", join(cwd, "out.json")]);
  });

  test("refuses outside a Herdr app terminal", () => {
    const { run, dir } = setup(piTerminal);
    const result = run(["open", "docs/plan.md"], { cwd: project() });
    expect(result.status).not.toBe(0);
    expect(result.stderr).toMatch(/HC_TERMINAL_ID/);
    expect(() => readFileSync(join(dir, "popup.json"))).toThrow();
  });

  test("refuses a path that doesn't exist", () => {
    const { run, dir } = setup(piTerminal);
    const result = run(["open", "missing.md"], { cwd: project(), env: { HC_TERMINAL_ID: "t2" } });
    expect(result.status).not.toBe(0);
    expect(result.stderr).toMatch(/no such file/);
    expect(() => readFileSync(join(dir, "popup.json"))).toThrow();
  });
});

describe("as herdr: pane read and agent read", () => {
  const read = (text: string) => JSON.stringify({ text, complete: true, how: "history" });

  test("pane read gives the last --lines lines, without the screen's blank rows", () => {
    const { run, calls } = setup({ ...piTerminal, read: read("one\ntwo\nthree\nfour\n\n\n") });
    const args = ["--source", "recent-unwrapped", "--lines", "2", "--format", "text"];
    const result = run(["pane", "read", TERMINAL, ...args]);
    expect(result.status, result.stderr).toBe(0);
    expect(result.stdout).toBe("three\nfour\n");
    expect(calls()).toContainEqual(["read", "--json", TERMINAL, "--lines", "2"]);
  });

  test("agent read gives the recent output too", () => {
    const { run } = setup({ ...piTerminal, read: read("one\ntwo\n") });
    const args = ["--source", "recent-unwrapped", "--format", "text"];
    expect(run(["agent", "read", TERMINAL, ...args]).stdout).toBe("one\ntwo\n");
  });

  test("fails for a terminal that doesn't exist", () => {
    const { run } = setup();
    expect(run(["pane", "read", TERMINAL, "--lines", "2"]).status).not.toBe(0);
  });
});

describe("as herdr: agent prompt", () => {
  const sends = (calls: string[][]) => calls.filter((argv) => argv[0] === "send");

  test("sends the feedback to the agent's terminal, which pastes it and presses Enter", () => {
    const { run, calls } = setup(piTerminal);
    const result = run(["agent", "prompt", TERMINAL, "## 1. Feedback\n> fix it"]);
    expect(result.status, result.stderr).toBe(0);
    expect(sends(calls())).toEqual([
      ["send", "--json", TERMINAL, "--", "## 1. Feedback\n> fix it"],
    ]);
  });

  test("sends feedback that starts with a dash as text, not a flag", () => {
    const { run, calls } = setup(piTerminal);
    run(["agent", "prompt", TERMINAL, "--force"]);
    expect(sends(calls())).toEqual([["send", "--json", TERMINAL, "--", "--force"]]);
  });

  test("strips control characters, so quoted terminal text can't end the paste early", () => {
    const { run, calls } = setup(piTerminal);
    run(["agent", "prompt", TERMINAL, "before\x1b[201~\r\x03after\tend"]);
    expect(sends(calls())[0]?.at(-1)).toBe("before[201~after\tend");
  });

  test("refuses while the agent waits at a prompt, typing nothing", () => {
    const { run, calls } = setup({
      get: terminal({
        foreground: { argv: ["pi"], cwd: "/w", name: "pi", pid: 4242 },
        status: { app: "pi", state: "blocked", kind: "permission" },
      }),
    });
    const result = run(["agent", "prompt", TERMINAL, "feedback"]);
    expect(result.status).not.toBe(0);
    expect(JSON.parse(result.stderr).error.code).toBe("agent_blocked");
    expect(sends(calls())).toEqual([]);
  });

  test("refuses while another of the agent's 7501 records is blocked", () => {
    const { run, calls } = setup({
      get: terminal({
        foreground: { argv: ["pi"], cwd: "/w", name: "pi", pid: 4242 },
        status: { app: "pi", state: "working" },
        records: { sub: { app: "pi", state: "blocked", kind: "question" } },
      }),
    });
    const result = run(["agent", "prompt", TERMINAL, "feedback"]);
    expect(JSON.parse(result.stderr).error.code).toBe("agent_blocked");
    expect(sends(calls())).toEqual([]);
  });

  test("reports a block hc finds at send time as the agent being blocked", () => {
    const { run } = setup({
      ...piTerminal,
      "send-error": JSON.stringify({ error: { kind: "blocked", message: "it is blocked" } }),
    });
    const result = run(["agent", "prompt", TERMINAL, "feedback"]);
    expect(result.status).not.toBe(0);
    expect(JSON.parse(result.stderr).error.code).toBe("agent_blocked");
  });

  test("delivers to an agent that reports status, whatever its name", () => {
    const { run, calls } = setup(aiderTerminal);
    const result = run(["agent", "prompt", TERMINAL, "feedback"]);
    expect(result.status, result.stderr).toBe(0);
    expect(sends(calls())).toHaveLength(1);
  });

  test("reports a terminal that doesn't exist", () => {
    const { run } = setup();
    const result = run(["agent", "prompt", TERMINAL, "feedback"]);
    expect(result.status).not.toBe(0);
    expect(JSON.parse(result.stderr).error.code).toBe("pane_not_found");
  });

  test("refuses a terminal with no agent in it, typing nothing", () => {
    const { run, calls } = setup(shellTerminal);
    const result = run(["agent", "prompt", TERMINAL, "feedback"]);
    expect(result.status).not.toBe(0);
    expect(JSON.parse(result.stderr).error.code).toBe("agent_not_found");
    expect(sends(calls())).toEqual([]);
  });
});
