import { accessSync, constants, readFileSync, statSync } from "node:fs";
import { delimiter, join } from "node:path";
import { parseFrontmatter, type ExtensionAPI, type Skill } from "@earendil-works/pi-coding-agent";

/** Conditions a skill needs to be useful; every one must hold. */
interface Gate {
  /** `NAME` (set and non-empty) or `NAME=VALUE` (exactly that value). */
  env: string[];
  /** Commands that must be on PATH. */
  bin: string[];
}

const NO_GATE: Gate = { env: [], bin: [] };

/** Reads a space-separated string or a YAML list of strings. */
function words(value: unknown): string[] {
  if (Array.isArray(value)) return value.flatMap(words);
  return typeof value === "string" ? value.split(/\s+/).filter(Boolean) : [];
}

/** Reads `requires-env` / `requires-bin` from frontmatter metadata or a setting. */
function gateFrom(fields: unknown): Gate {
  if (typeof fields !== "object" || fields === null) return NO_GATE;
  const record = fields as Record<string, unknown>;
  return { env: words(record["requires-env"]), bin: words(record["requires-bin"]) };
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
  return { env: [...a.env, ...b.env], bin: [...a.bin, ...b.bin] };
}

function envHolds(requirement: string) {
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

function gateHolds(gate: Gate) {
  return gate.env.every(envHolds) && gate.bin.every(onPath);
}

/**
 * Hides skills from the model's skill list when the environment they need is
 * absent, so they cost no context there. `/skill:name` still loads them.
 */
export default function skillGates(pi: ExtensionAPI) {
  // Env, PATH and settings are fixed until /reload reloads this extension, so
  // each skill is judged once and the prompt stays stable across turns.
  const verdicts = new Map<string, boolean>();
  let configured: Record<string, unknown> | undefined;
  const isUseful = (skill: Skill) => {
    let verdict = verdicts.get(skill.filePath);
    if (verdict === undefined) {
      configured ??= settingsGates(pi);
      verdict = gateHolds(bothGates(frontmatterGate(skill), gateFrom(configured[skill.name])));
      verdicts.set(skill.filePath, verdict);
    }
    return verdict;
  };

  pi.on("before_agent_start", (event) => {
    const { skills } = event.systemPromptOptions;
    const useful = skills.filter(isUseful);
    skills.splice(0, skills.length, ...useful);
  });
}
