import assert from "node:assert/strict";
import { chmodSync, mkdirSync, mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import type {
  BeforeAgentStartEvent,
  ExtensionAPI,
  ExtensionContext,
  Skill,
  ToolInfo,
} from "@earendil-works/pi-coding-agent";
import { afterEach, test, vi } from "vitest";
import skillGates from "./skill-gates.js";

type Handler = (event: BeforeAgentStartEvent, ctx: ExtensionContext) => unknown;

let root: string | undefined;
afterEach(() => {
  vi.unstubAllEnvs();
  if (root) rmSync(root, { recursive: true, force: true });
  root = undefined;
});

function tempRoot() {
  root ??= mkdtempSync(join(tmpdir(), "skill-gates-"));
  return root;
}

function skill(name: string, frontmatter = ""): Skill {
  const dir = join(tempRoot(), "skills", name);
  mkdirSync(dir, { recursive: true });
  const filePath = join(dir, "SKILL.md");
  writeFileSync(
    filePath,
    `---\nname: ${name}\ndescription: Test skill.\n${frontmatter}---\n\n# ${name}\n`,
  );
  return { name, description: "Test skill.", filePath, baseDir: dir } as Skill;
}

/** Loads the extension fresh, as pi does per process, and runs one turn. */
interface Session {
  settings?: Record<string, unknown>;
  /** Whether a human is at a UI; subagents and `pi -p` run without one. */
  hasUI?: boolean;
  /** Tools declared to the model. */
  activeTools?: string[];
  /** Every registered tool; defaults to the active tools, exposed directly. */
  allTools?: Partial<ToolInfo>[];
}

async function visibleSkills(skills: Skill[], session: Session = {}) {
  const { settings = {}, hasUI = true, activeTools = [] } = session;
  const allTools = session.allTools ?? activeTools.map((name) => ({ name, exposure: "direct" }));
  let handler: Handler | undefined;
  const recordingPi = {
    on(event: string, registered: Handler) {
      if (event === "before_agent_start") handler = registered;
    },
    getSettings: () => structuredClone(settings),
    getActiveTools: () => [...activeTools],
    getAllTools: () => allTools,
  } as unknown as ExtensionAPI;
  skillGates(recordingPi);
  assert.ok(handler);

  const event = {
    type: "before_agent_start",
    messageType: "user",
    prompt: "hi",
    systemPrompt: "",
    systemPromptOptions: { skills: [...skills] },
  } as unknown as BeforeAgentStartEvent;
  await handler(event, { hasUI } as ExtensionContext);
  return event.systemPromptOptions.skills.map((s) => s.name);
}

test("a skill requiring a human is listed only when pi has a UI", async () => {
  const interactive = skill("interview", 'metadata:\n  requires-ui: "true"\n');
  const plain = skill("plain");

  assert.deepEqual(await visibleSkills([interactive, plain], { hasUI: false }), ["plain"]);
  assert.deepEqual(await visibleSkills([interactive, plain], { hasUI: true }), [
    "interview",
    "plain",
  ]);
});

test("a skill requiring tools is listed only when the model can reach them", async () => {
  const gated = skill("cli", "metadata:\n  requires-tool: bash lsp_hover\n");
  const codemodeTools: Partial<ToolInfo>[] = [
    { name: "bash", exposure: "direct" },
    { name: "lsp_hover", exposure: "codemode" },
    { name: "codemode", exposure: "direct", reachesTools: () => "all" },
  ];

  // A read-only subagent: neither tool is active or reachable.
  assert.deepEqual(await visibleSkills([gated], { activeTools: ["read"] }), []);

  // bash is active, but lsp_hover is only reachable through codemode.
  assert.deepEqual(
    await visibleSkills([gated], { activeTools: ["bash"], allTools: codemodeTools }),
    [],
  );
  assert.deepEqual(
    await visibleSkills([gated], { activeTools: ["bash", "codemode"], allTools: codemodeTools }),
    ["cli"],
  );
});

test("a tool requirement can name alternatives, such as either shell", async () => {
  const gated = skill("shell-cli", "metadata:\n  requires-tool: bash|powershell\n");

  assert.deepEqual(await visibleSkills([gated], { activeTools: ["read"] }), []);
  assert.deepEqual(await visibleSkills([gated], { activeTools: ["powershell"] }), ["shell-cli"]);
  assert.deepEqual(await visibleSkills([gated], { activeTools: ["bash"] }), ["shell-cli"]);
});

test("a skill requiring an env var is listed only when that var has the required value", async () => {
  const gated = skill("multiplexer", "metadata:\n  requires-env: MUX_ENV=1\n");
  const plain = skill("plain");

  vi.stubEnv("MUX_ENV", undefined);
  assert.deepEqual(await visibleSkills([gated, plain]), ["plain"]);

  vi.stubEnv("MUX_ENV", "0");
  assert.deepEqual(await visibleSkills([gated, plain]), ["plain"]);

  vi.stubEnv("MUX_ENV", "1");
  assert.deepEqual(await visibleSkills([gated, plain]), ["multiplexer", "plain"]);
});

test("env requirements accept a bare name, values containing '=', and YAML lists", async () => {
  const gated = skill("session", "metadata:\n  requires-env: [IN_SESSION, SESSION_URL=a=b]\n");

  vi.stubEnv("IN_SESSION", "yes");
  vi.stubEnv("SESSION_URL", "a");
  assert.deepEqual(await visibleSkills([gated]), []);

  vi.stubEnv("SESSION_URL", "a=b");
  assert.deepEqual(await visibleSkills([gated]), ["session"]);

  vi.stubEnv("IN_SESSION", "");
  assert.deepEqual(await visibleSkills([gated]), []);
});

test("the skillGates setting gates a skill alongside its own frontmatter", async () => {
  const installed = skill("installed");
  const own = skill("own", "metadata:\n  requires-env: OWN_ENV\n");
  const settings = {
    skillGates: {
      installed: { "requires-env": "MUX_ENV=1" },
      own: { "requires-env": "MUX_ENV=1" },
    },
  };

  vi.stubEnv("MUX_ENV", undefined);
  vi.stubEnv("OWN_ENV", "yes");
  assert.deepEqual(await visibleSkills([installed, own], { settings }), []);

  vi.stubEnv("MUX_ENV", "1");
  assert.deepEqual(await visibleSkills([installed, own], { settings }), ["installed", "own"]);

  // A setting adds to the frontmatter gate; it cannot lift it.
  vi.stubEnv("OWN_ENV", undefined);
  assert.deepEqual(await visibleSkills([installed, own], { settings }), ["installed"]);
});

test("a skill requiring a command is listed only when that command is on PATH", async () => {
  const gated = skill("window-manager", "metadata:\n  requires-bin: fakewm\n");
  const bin = join(tempRoot(), "bin");
  mkdirSync(bin);

  vi.stubEnv("PATH", bin);
  assert.deepEqual(await visibleSkills([gated]), []);

  const program = join(bin, "fakewm");
  writeFileSync(program, "#!/bin/sh\n");
  chmodSync(program, 0o755);
  assert.deepEqual(await visibleSkills([gated]), ["window-manager"]);
});
