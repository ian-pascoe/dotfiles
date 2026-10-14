// Every folder in dot_themes/ is a theme variant (see CONTEXT.md): a complete set
// of per-app files that ~/.config/theme can point at. This keeps the variants
// complete and their families consistent. Source names carry the attributes:
// `empty_light.mode` deploys the empty marker file `light.mode`.
import { existsSync, readdirSync, readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { describe, expect, test } from "vitest";

const themes = dirname(fileURLToPath(import.meta.url));
const source = dirname(themes);

// Files every variant has, as deployed paths under ~/.themes/<variant>/.
const requiredFiles = [
  "bat.tmTheme",
  "borders.sh",
  "btop.theme",
  "ghostty.conf",
  "glazewm.yaml",
  "k9s.yaml",
  "lsd.yaml",
  "pi.json",
  "tern.json",
  "yasb.css",
  "yazi/theme.toml",
];

// Folders in dot_themes/ that are documentation, not variants.
const notThemes = new Set(["docs", "node_modules"]);

const variants = readdirSync(themes, { withFileTypes: true })
  .filter((entry) => entry.isDirectory() && !notThemes.has(entry.name))
  .map((entry) => entry.name)
  .sort();

const read = (...path: string[]) => readFileSync(join(...path), "utf8");
const isLight = (variant: string) => existsSync(join(themes, variant, "empty_light.mode"));

function familyOf(variant: string): string {
  const file = join(themes, variant, "family");
  return existsSync(file) ? readFileSync(file, "utf8").trim() : variant;
}

// Names of the Lua table entries in `block`: `name = {` or `['name'] = {` at the
// two-space indent of the colorscheme.lua tables.
function luaKeys(block: string): string[] {
  return [...block.matchAll(/^ {2}(?:\['([^']+)'\]|(\w+)) = \{/gm)].map(
    (match) => (match[1] ?? match[2])!,
  );
}

// Neovim's theme_specs entries plus the variants aliased to another entry's plugin.
const neovimSpecs = (() => {
  const lua = read(source, "dot_config/nvim/lua/plugins/colorscheme.lua");
  const specs = lua.match(/^local theme_specs = \{\n([\s\S]*?)^\}/m)?.[1] ?? "";
  const aliases = lua.match(/^for name, variant in pairs\(\{\n([\s\S]*?)^\}\) do/m)?.[1] ?? "";
  return new Set([...luaKeys(specs), ...luaKeys(aliases)]);
})();

// Wallpapers are chezmoi externals so the source stays free of large binaries.
const externalWallpapers = new Set(
  [
    ...read(source, ".chezmoiexternal.toml.tmpl").matchAll(
      /^\["\.themes\/([^/"]+)\/backgrounds\//gm,
    ),
  ].map((match) => match[1]!),
);

// Set-Theme.ps1 sets Windows Terminal's colorScheme and theme to the variant's name.
const windowsTerminal = JSON.parse(read(source, "dot_config/windows-terminal/settings.json")) as {
  schemes: { name: string }[];
  themes: { name: string }[];
};

// Oh My Pi loads tern.json as its `current` theme (dot_omp/private_agent/themes)
// and rejects a theme missing any of these; thinkingMax and
// assistantMessageText are optional.
const ompColorTokens = `accent border borderAccent borderMuted success error warning muted dim text
  thinkingText selectedBg userMessageBg customMessageBg toolPendingBg toolSuccessBg toolErrorBg
  statusLineBg userMessageText customMessageText customMessageLabel toolTitle toolOutput mdHeading
  mdLink mdLinkUrl mdCode mdCodeBlock mdCodeBlockBorder mdQuote mdQuoteBorder mdHr mdListBullet
  toolDiffAdded toolDiffRemoved toolDiffContext syntaxComment syntaxKeyword syntaxFunction
  syntaxVariable syntaxString syntaxNumber syntaxType syntaxOperator syntaxPunctuation thinkingOff
  thinkingMinimal thinkingLow thinkingMedium thinkingHigh thinkingXhigh bashMode pythonMode
  statusLineSep statusLineModel statusLinePath statusLineGitClean statusLineGitDirty
  statusLineContext statusLineSpend statusLineStaged statusLineDirty statusLineUntracked
  statusLineOutput statusLineCost statusLineSubagents`.split(/\s+/);

test("there are theme variants", () => {
  expect(variants.length).toBeGreaterThan(0);
});

describe.each(variants)("%s", (variant) => {
  const dir = join(themes, variant);

  test.each(requiredFiles)("has %s", (file) => {
    expect(existsSync(join(dir, file))).toBe(true);
  });

  test("ghostty.conf has inline colors and no catalog theme", () => {
    const conf = read(dir, "ghostty.conf");
    expect(conf).not.toMatch(/^\s*theme\s*=/m);
    expect(conf).toMatch(/^background\s*=\s*#[0-9a-f]{6}\s*$/im);
    expect(conf).toMatch(/^foreground\s*=\s*#[0-9a-f]{6}\s*$/im);
    const palette = [...conf.matchAll(/^palette\s*=\s*(\d+)\s*=\s*#[0-9a-f]{6}\s*$/gim)].map((m) =>
      Number(m[1]),
    );
    expect(palette.sort((a, b) => a - b)).toEqual(Array.from({ length: 16 }, (_, i) => i));
  });

  test("has a wallpaper entry or files", () => {
    const files = existsSync(join(dir, "backgrounds")) ? readdirSync(join(dir, "backgrounds")) : [];
    expect(externalWallpapers.has(variant) || files.length > 0).toBe(true);
  });

  test("has a Neovim spec", () => {
    expect(neovimSpecs.has(variant)).toBe(true);
  });

  test("has a Windows Terminal scheme and theme", () => {
    expect(windowsTerminal.schemes.map((scheme) => scheme.name)).toContain(variant);
    expect(windowsTerminal.themes.map((theme) => theme.name)).toContain(variant);
  });

  test("family file is one non-empty line", () => {
    const file = join(dir, "family");
    if (existsSync(file)) expect(read(file)).toMatch(/^[^\s\n][^\n]*\n$/);
  });

  test("pi.json name and appearance agree with the folder and light.mode", () => {
    const pi = JSON.parse(read(dir, "pi.json")) as { name?: string; appearance?: string };
    expect(pi.name).toBe(variant);
    expect(pi.appearance === "light").toBe(isLight(variant));
  });

  test("tern.json is a complete Oh My Pi theme", () => {
    const tern = JSON.parse(read(dir, "tern.json")) as {
      name?: string;
      vars?: Record<string, string | number>;
      colors: Record<string, string | number>;
    };
    expect(typeof tern.name).toBe("string");
    expect(ompColorTokens.filter((token) => !(token in tern.colors))).toEqual([]);
    // A string color is a hex value, "" (terminal default) or a var name.
    const unresolved = Object.entries(tern.colors).filter(
      ([, value]) =>
        typeof value === "string" &&
        value !== "" &&
        !/^#[0-9a-f]{6}$/i.test(value) &&
        !(value in (tern.vars ?? {})),
    );
    expect(unresolved).toEqual([]);
  });
});

describe("families", () => {
  const families = new Map<string, string[]>();
  for (const variant of variants) {
    const family = familyOf(variant);
    families.set(family, [...(families.get(family) ?? []), variant]);
  }

  test.each([...families])("%s has at most one variant per mode", (_family, members) => {
    expect(members.filter(isLight).length).toBeLessThanOrEqual(1);
    expect(members.filter((member) => !isLight(member)).length).toBeLessThanOrEqual(1);
  });

  test("a family name does not hide another family's variant", () => {
    // theme-resolve lets a family name win over a folder name, so a folder named
    // like a family it does not belong to could never be chosen by name.
    for (const [family, members] of families) {
      if (variants.includes(family)) expect(members, family).toContain(family);
    }
  });
});
