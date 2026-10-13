// tern/ holds Tern's config once; each OS's config directory in the source
// state is a tree of stubs that include it. This keeps those trees in step.
import { readFileSync, readdirSync } from "node:fs";
import { dirname, join, relative } from "node:path";
import { fileURLToPath } from "node:url";
import { expect, test } from "vitest";

const tern = dirname(fileURLToPath(import.meta.url));
const source = dirname(tern);

// Tern's <config> per OS, as chezmoi source paths.
const roots = {
  darwin: "Library/private_Application Support/private_Tern",
  linux: "dot_config/tern",
  windows: "AppData/Roaming/Tern",
};

const settings = [
  "{{- /* chezmoi:modify-template */ -}}",
  '{{- includeTemplate "tern-settings.json.tmpl" . -}}',
  "",
].join("\n");

function files(dir: string): string[] {
  return readdirSync(dir, { recursive: true, withFileTypes: true })
    .filter((entry) => entry.isFile())
    .map((entry) => relative(dir, join(entry.parentPath, entry.name)))
    .sort();
}

const plugins = files(join(tern, "plugins")).map((file) => join("plugins", file));

test.each(Object.entries(roots))("%s tree includes every file in tern/", (_os, root) => {
  const dir = join(source, root);
  const expected = [...plugins.map((file) => `${file}.tmpl`), "modify_settings.json"].sort();
  expect(files(dir)).toEqual(expected);

  for (const file of plugins) {
    expect(readFileSync(join(dir, `${file}.tmpl`), "utf8"), file).toBe(
      `{{- include "tern/${file}" -}}\n`,
    );
  }
  expect(readFileSync(join(dir, "modify_settings.json"), "utf8")).toBe(settings);
});
