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

/**
 * Gates for skills whose SKILL.md an installer owns (the skills lockfile,
 * `rex skill setup`), where a frontmatter gate would be overwritten.
 * Gate your own skills with `metadata.requires-env` / `requires-bin` instead.
 */
const INSTALLER_OWNED_GATES: Record<string, Gate> = {
  herdr: { env: ["HERDR_ENV=1"], bin: [] },
  "plannotator-tui": { env: ["HERDR_ENV=1"], bin: [] },
  rex: { env: [], bin: ["rex"] },
};

const NO_GATE: Gate = { env: [], bin: [] };

/** Reads a space-separated string or a YAML list of strings. */
function words(value: unknown): string[] {
  if (Array.isArray(value)) return value.flatMap(words);
  return typeof value === "string" ? value.split(/\s+/).filter(Boolean) : [];
}

/** An unreadable SKILL.md is left ungated: pi reports broken skills itself. */
function frontmatterGate(skill: Skill): Gate {
  let metadata: unknown;
  try {
    metadata = parseFrontmatter(readFileSync(skill.filePath, "utf8")).frontmatter.metadata;
  } catch {
    return NO_GATE;
  }
  const fields = (metadata ?? {}) as Record<string, unknown>;
  return { env: words(fields["requires-env"]), bin: words(fields["requires-bin"]) };
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
  // Env and PATH are fixed for the process, so each skill is judged once.
  const verdicts = new Map<string, boolean>();
  const isUseful = (skill: Skill) => {
    let verdict = verdicts.get(skill.filePath);
    if (verdict === undefined) {
      verdict = gateHolds(
        bothGates(frontmatterGate(skill), INSTALLER_OWNED_GATES[skill.name] ?? NO_GATE),
      );
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
