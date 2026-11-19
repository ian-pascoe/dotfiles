// Zed's config lives once in dot_config/zed (macOS and Linux read ~/.config/zed);
// Windows reads %APPDATA%\Zed, whose source tree holds only stubs that include it.
// This keeps the two in step and the theme wiring pointed at set-theme's link.
import { readFileSync, readdirSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { expect, test } from "vite-plus/test";
import { zedThemeName } from "../../dot_themes/tools/new-variant";

const zed = dirname(fileURLToPath(import.meta.url));
const source = dirname(dirname(zed));
const windows = join(source, "AppData/Roaming/Zed");

const configFiles = readdirSync(zed)
  .filter((file) => file.endsWith(".json"))
  .sort();

test("the Windows tree includes every config file", () => {
  expect(configFiles).toEqual(["keymap.json", "settings.json", "tasks.json"]);
  expect(readdirSync(windows).sort()).toEqual(configFiles.map((file) => `${file}.tmpl`));
  for (const file of configFiles) {
    expect(readFileSync(join(windows, `${file}.tmpl`), "utf8"), file).toBe(
      `{{- include "dot_config/zed/${file}" -}}\n`,
    );
  }
});

test("settings.json selects the theme every zed.json defines", () => {
  const settings = readFileSync(join(zed, "settings.json"), "utf8");
  expect(settings).toMatch(new RegExp(`^\\s*"theme": "${zedThemeName}",?$`, "m"));
});

test("themes/ links the current variant's zed.json", () => {
  expect(readFileSync(join(zed, "themes/symlink_dotfiles.json.tmpl"), "utf8")).toContain(
    '".config/theme/zed.json"',
  );
});

// Zed's keymap is JSON with comments and trailing commas.
function readJsonc(file: string): unknown {
  let json = "";
  let inString = false;
  const text = readFileSync(file, "utf8");
  for (let i = 0; i < text.length; i++) {
    const char = text[i];
    if (inString) {
      json += char;
      if (char === "\\") json += text[++i];
      else if (char === '"') inString = false;
    } else if (char === '"') {
      inString = true;
      json += char;
    } else if (char === "/" && text[i + 1] === "/") {
      while (i < text.length && text[i] !== "\n") i++;
      json += "\n";
    } else {
      json += char;
    }
  }
  return JSON.parse(json.replace(/,(\s*[}\]])/g, "$1"));
}

// A prefix that is also a complete binding (vim's `space` moves right, the
// project panel's opens) resolves after 1s, taking the which-key popup with it.
test("every block with leader sequences unbinds bare space", () => {
  const keymap = readJsonc(join(zed, "keymap.json")) as {
    context?: string;
    bindings: Record<string, unknown>;
  }[];
  for (const { context, bindings } of keymap) {
    if (!Object.keys(bindings).some((key) => key.startsWith("space "))) continue;
    expect(bindings, context).toHaveProperty("space", null);
  }
});
