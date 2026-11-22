#!/usr/bin/env node
// Claude Code PostToolUse hook (Edit|Write): formats the edited file.
// Runs each formatter in formatters.json (next to this hook) whose extensions
// or fileNames match the file, from its root-marker directory; a formatter with
// requireRootMarker is skipped when no marker is found. When a formatter
// changes the file, tells Claude what changed so its view of the file is not
// stale.
import { spawnSync } from "node:child_process";
import { existsSync, mkdtempSync, readdirSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { basename, dirname, extname, join, relative } from "node:path";
import { fileURLToPath } from "node:url";

const DIFF_MAX_LINES = 60;
const DIFF_MAX_BYTES = 6000;
const DIFF_MAX_CHANGED = 100;

function readJson(file) {
  try {
    return JSON.parse(readFileSync(file, "utf8"));
  } catch {
    return undefined;
  }
}

function globToRegExp(glob) {
  const body = glob
    .replace(/[.+^${}()|[\]\\]/g, "\\$&")
    .replace(/\*/g, ".*")
    .replace(/\?/g, ".");
  return new RegExp(`^${body}$`);
}

function findRoot(file, markers) {
  if (!markers?.length) return undefined;
  const patterns = markers.map(globToRegExp);
  for (let dir = dirname(file); ; dir = dirname(dir)) {
    let entries = [];
    try {
      entries = readdirSync(dir);
    } catch {}
    if (entries.some((name) => patterns.some((re) => re.test(name)))) return dir;
    if (dirname(dir) === dir) return undefined;
  }
}

function matches(file, files = {}) {
  return (
    (files.extensions ?? []).includes(extname(file)) ||
    (files.fileNames ?? []).includes(basename(file))
  );
}

const input = JSON.parse(readFileSync(0, "utf8") || "{}");
const file = input.tool_input?.file_path;
const cwd = input.cwd || process.cwd();
if (!file || !existsSync(file)) process.exit(0);

const config = readJson(join(dirname(fileURLToPath(import.meta.url)), "formatters.json")) ?? {};
const timeout = config.timeoutMs ?? 30000;
const formatters = config.formatters ?? {};

const original = readFileSync(file, "utf8");
const ran = [];
const warnings = [];
for (const [name, f] of Object.entries(formatters)) {
  if (!f?.command || !matches(file, f.files)) continue;
  const root = findRoot(file, f.rootMarkers);
  if (f.requireRootMarker && !root) continue;
  const args = (f.args ?? []).map((a) => a.replaceAll("$FILE", file));
  const before = readFileSync(file, "utf8");
  const r = spawnSync(f.command, args, {
    cwd: root ?? cwd,
    env: { ...process.env, ...f.environment },
    encoding: "utf8",
    timeout,
  });
  if (readFileSync(file, "utf8") !== before) ran.push(name);
  if (r.error)
    warnings.push(
      `${name}: ${r.error.code === "ETIMEDOUT" ? `timed out after ${timeout}ms` : r.error.message}`,
    );
  else if (r.status !== 0)
    warnings.push(
      `${name} exited ${r.status}: ${(r.stderr || r.stdout).trim().split("\n").slice(0, 5).join("\n")}`,
    );
}

const parts = [];
const final = readFileSync(file, "utf8");
if (final !== original) {
  const tmp = mkdtempSync(join(tmpdir(), "cc-format-"));
  const before = join(tmp, basename(file));
  writeFileSync(before, original);
  const diff =
    spawnSync("git", ["diff", "--no-index", "--no-color", "-U3", before, file], {
      encoding: "utf8",
    }).stdout ?? "";
  rmSync(tmp, { recursive: true, force: true });
  const body = diff
    .split("\n")
    .slice(4)
    .filter((l) => l !== "");
  const changed = body.filter((l) => /^[+-]/.test(l)).length;
  parts.push(
    `${relative(cwd, file) || file} was reformatted by ${ran.join(", ") || "a formatter"} after your edit; your view of it is stale.`,
  );
  const shown = body.slice(0, DIFF_MAX_LINES).join("\n");
  if (
    changed <= DIFF_MAX_CHANGED &&
    body.length <= DIFF_MAX_LINES &&
    shown.length <= DIFF_MAX_BYTES
  ) {
    parts.push(`Formatter changes ('-' your text, '+' now on disk):\n${shown}`);
  } else {
    parts.push("The change is large; re-read the file before editing it again.");
  }
}
if (warnings.length) parts.push(`Formatter warnings:\n${warnings.join("\n")}`);
if (parts.length) {
  process.stdout.write(
    JSON.stringify({
      hookSpecificOutput: { hookEventName: "PostToolUse", additionalContext: parts.join("\n\n") },
    }),
  );
}
