import { accessSync, constants, readFileSync, statSync } from "node:fs";
import { delimiter, join } from "node:path";
import { parseFrontmatter, type ExtensionAPI, type Skill } from "@earendil-works/pi-coding-agent";

/** Conditions a skill needs to be useful; every one must hold. */
interface Gate {
  /**
   * `NAME` (set and non-empty) or `NAME=VALUE` (exactly that value); a leading `!` requires
   * the opposite.
   */
  env: string[];
  /** Commands that must be on PATH. */
  bin: string[];
  /** Needs a human at a UI; subagents and `pi -p` have none. */
  ui: boolean;
  /**
   * Tools the model must be able to reach, directly or through codemode;
   * `bash|powershell` is met by either.
   */
  tools: string[];
}

const NO_GATE: Gate = { env: [], bin: [], ui: false, tools: [] };

/** What the session offers, read once on the first turn. */
interface Session {
  hasUI: boolean;
  tools: Set<string>;
}

/**
 * Active tools, plus the `codemode` and `deferred` tools an active tool such as
 * codemode reaches. A tool activated later (by tool search) does not count.
 */
function reachableTools(pi: ExtensionAPI): Set<string> {
  const active = new Set(pi.getActiveTools());
  const all = pi.getAllTools().filter((tool) => tool.exposure !== "hidden");
  const reacher = all.some((tool) => active.has(tool.name) && tool.reachesTools);
  const reached = (tool: (typeof all)[number]) =>
    reacher && (tool.exposure === "codemode" || tool.exposure === "deferred");
  return new Set(
    all.filter((tool) => active.has(tool.name) || reached(tool)).map((tool) => tool.name),
  );
}

/** Reads a space-separated string or a YAML list of strings. */
function words(value: unknown): string[] {
  if (Array.isArray(value)) return value.flatMap(words);
  return typeof value === "string" ? value.split(/\s+/).filter(Boolean) : [];
}

/** Reads `requires-env` / `requires-bin` from frontmatter metadata or a setting. */
function gateFrom(fields: unknown): Gate {
  if (typeof fields !== "object" || fields === null) return NO_GATE;
  const record = fields as Record<string, unknown>;
  return {
    env: words(record["requires-env"]),
    bin: words(record["requires-bin"]),
    // Agent Skills metadata values are strings; settings JSON can say `true`.
    ui: record["requires-ui"] === true || record["requires-ui"] === "true",
    tools: words(record["requires-tool"]),
  };
}

/** An unreadable SKILL.md is left ungated: pi reports broken skills itself. */
function frontmatterGate(skill: Skill): Gate {
  try {
    return gateFrom(parseFrontmatter(readFileSync(skill.filePath, "utf8")).frontmatter.metadata);
  } catch {
    return NO_GATE;
  }
}

/**
 * The `skillGates` setting, keyed by skill name, gates skills whose SKILL.md
 * an installer owns (the skills lockfile, `rex skill setup`), where a
 * frontmatter gate would be overwritten.
 */
function settingsGates(pi: ExtensionAPI): Record<string, unknown> {
  const { skillGates } = pi.getSettings() as { skillGates?: unknown };
  return typeof skillGates === "object" && skillGates !== null
    ? (skillGates as Record<string, unknown>)
    : {};
}

function bothGates(a: Gate, b: Gate): Gate {
  return {
    env: [...a.env, ...b.env],
    bin: [...a.bin, ...b.bin],
    ui: a.ui || b.ui,
    tools: [...a.tools, ...b.tools],
  };
}

function envHolds(requirement: string): boolean {
  if (requirement.startsWith("!")) return !envHolds(requirement.slice(1));
  const split = requirement.indexOf("=");
  if (split === -1) return !!process.env[requirement];
  return process.env[requirement.slice(0, split)] === requirement.slice(split + 1);
}

function isExecutable(path: string) {
  try {
    accessSync(path, constants.X_OK);
    return statSync(path).isFile();
  } catch {
    return false;
  }
}

function onPath(command: string) {
  // Windows runs `glazewm` as `glazewm.exe` and the like, through PATHEXT.
  const extensions =
    process.platform === "win32"
      ? (process.env.PATHEXT ?? ".COM;.EXE;.BAT;.CMD").split(";").filter(Boolean)
      : [""];
  return (process.env.PATH ?? "")
    .split(delimiter)
    .filter(Boolean)
    .some((dir) => extensions.some((ext) => isExecutable(join(dir, command + ext))));
}

function gateHolds(gate: Gate, session: Session) {
  return (
    (!gate.ui || session.hasUI) &&
    gate.tools.every((tool) => tool.split("|").some((name) => session.tools.has(name))) &&
    gate.env.every(envHolds) &&
    gate.bin.every(onPath)
  );
}

/**
 * Hides skills from the model's skill list when the environment they need is
 * absent, so they cost no context there. `/skill:name` still loads them.
 *
 * A skill declares its gate in frontmatter `metadata`, or, when an installer
 * owns its SKILL.md, under the `skillGates` setting keyed by skill name:
 * `requires-env`, `requires-bin`, `requires-tool` and `requires-ui`.
 */
export default function skillGates(pi: ExtensionAPI) {
  // Each skill is judged once, on the first turn it appears, so the prompt
  // stays stable across turns; /reload reloads this extension and judges again.
  const verdicts = new Map<string, boolean>();
  let configured: Record<string, unknown> | undefined;
  let session: Session | undefined;

  pi.on("before_agent_start", (event, ctx) => {
    const gates = (configured ??= settingsGates(pi));
    const offered = (session ??= { hasUI: ctx.hasUI, tools: reachableTools(pi) });
    const isUseful = (skill: Skill) => {
      let verdict = verdicts.get(skill.filePath);
      if (verdict === undefined) {
        const gate = bothGates(frontmatterGate(skill), gateFrom(gates[skill.name]));
        verdict = gateHolds(gate, offered);
        verdicts.set(skill.filePath, verdict);
      }
      return verdict;
    };
    const { skills } = event.systemPromptOptions;
    const useful = skills.filter(isUseful);
    skills.splice(0, skills.length, ...useful);
  });
}
