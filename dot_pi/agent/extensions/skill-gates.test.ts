import assert from "node:assert/strict";
import { chmodSync, mkdirSync, mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import type {
  BeforeAgentStartEvent,
  ExtensionAPI,
  ExtensionContext,
  Skill,
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
async function visibleSkills(skills: Skill[]) {
  let handler: Handler | undefined;
  const recordingPi = {
    on(event: string, registered: Handler) {
      if (event === "before_agent_start") handler = registered;
    },
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
  await handler(event, {} as ExtensionContext);
  return event.systemPromptOptions.skills.map((s) => s.name);
}

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

test("installer-owned skills are gated without editing their frontmatter", async () => {
  const herdr = skill("herdr");
  const tui = skill("plannotator-tui");

  vi.stubEnv("HERDR_ENV", undefined);
  assert.deepEqual(await visibleSkills([herdr, tui]), []);

  vi.stubEnv("HERDR_ENV", "1");
  assert.deepEqual(await visibleSkills([herdr, tui]), ["herdr", "plannotator-tui"]);
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
