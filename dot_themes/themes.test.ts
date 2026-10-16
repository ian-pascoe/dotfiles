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
  "helium/manifest.json",
  "k9s.yaml",
  "lsd.yaml",
  "pi.json",
  "tern.json",
  "yasb.css",
  "yazi/theme.toml",
];

// Folders in dot_themes/ that are documentation or tooling, not variants.
const notThemes = new Set(["docs", "tools", "node_modules"]);

const variants = readdirSync(themes, { withFileTypes: true })
  .filter((entry) => entry.isDirectory() && !notThemes.has(entry.name))
  .map((entry) => entry.name)
  .sort();

const read = (...path: string[]) => readFileSync(join(...path), "utf8");

// WCAG contrast ratio of two #rrggbb colors.
function contrast(a: string, b: string): number {
  const luminance = (hex: string) => {
    const [r, g, b] = [1, 3, 5].map((i) => {
      const c = parseInt(hex.slice(i, i + 2), 16) / 255;
      return c <= 0.03928 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4;
    });
    return 0.2126 * r! + 0.7152 * g! + 0.0722 * b!;
  };
  const [light, dark] = [luminance(a), luminance(b)].sort((x, y) => y - x);
  return (light! + 0.05) / (dark! + 0.05);
}
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

const colorschemeLua = read(source, "dot_config/nvim/lua/plugins/colorscheme.lua");
const themeSpecs = colorschemeLua.match(/^local theme_specs = \{\n([\s\S]*?)^\}/m)?.[1] ?? "";
const themeAliases =
  colorschemeLua.match(/^for name, variant in pairs\(\{\n([\s\S]*?)^\}\) do/m)?.[1] ?? "";

// Neovim's theme_specs entries plus the variants aliased to another entry's plugin.
const neovimSpecs = new Set([...luaKeys(themeSpecs), ...luaKeys(themeAliases)]);

// The hunk wrapper in interactive.sh maps a variant to a hunk diff theme with
// `name | other) echo theme ;;` lines and passes any other name through as is.
const hunkMapping = new Map(
  [
    ...read(source, "dot_config/shell/interactive.sh").matchAll(
      /^ +([a-z0-9| -]+)\) echo ([a-z0-9-]+) ;;$/gm,
    ),
  ].flatMap((match) => match[1]!.split("|").map((name) => [name.trim(), match[2]!] as const)),
);
const hunkThemes = new Set(
  read(themes, "tools/hunk-themes.txt")
    .split("\n")
    .filter((line) => line && !line.startsWith("#")),
);

// Wallpapers are chezmoi externals so the source stays free of large binaries.
const externals = read(source, ".chezmoiexternal.toml.tmpl");
const externalWallpapers = new Set(
  [...externals.matchAll(/^\["\.themes\/([^/"]+)\/backgrounds\//gm)].map((match) => match[1]!),
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

  test("maps to a hunk diff theme", () => {
    expect(hunkThemes).toContain(hunkMapping.get(variant) ?? variant);
  });

  test("has a Windows Terminal scheme and theme", () => {
    expect(windowsTerminal.schemes.map((scheme) => scheme.name)).toContain(variant);
    expect(windowsTerminal.themes.map((theme) => theme.name)).toContain(variant);
  });

  // yazi only finds flavors in ~/.config/yazi/flavors, so each flavor the
  // variant ships needs a link there.
  test("its yazi flavors are linked into yazi's flavors folder", () => {
    const flavors = join(dir, "yazi/flavors");
    const shipped = existsSync(flavors) ? readdirSync(flavors) : [];
    const unlinked = shipped.filter(
      (flavor) => !existsSync(join(source, "dot_config/yazi/flavors", `symlink_${flavor}.tmpl`)),
    );
    expect(unlinked).toEqual([]);
  });

  // k9s draws `default` as the terminal background, so a button whose text is
  // the background color needs a button background of its own.
  test("k9s dialog buttons have readable text", () => {
    const k9s = read(dir, "k9s.yaml");
    const background = read(dir, "ghostty.conf").match(/^background\s*=\s*(#[0-9a-f]{6})/im)![1]!;
    const color = (key: string) => {
      const value = k9s.match(new RegExp(`^\\s*${key}:\\s*(\\S+)`, "m"))![1]!.replace(/["']/g, "");
      if (value === "default") return background;
      if (!value.startsWith("*")) return value;
      return k9s.match(new RegExp(`&${value.slice(1)}\\s+["']?(#[0-9a-f]{6})`, "i"))![1]!;
    };
    for (const state of ["button", "buttonFocus"]) {
      const ratio = contrast(color(`${state}FgColor`), color(`${state}BgColor`));
      expect(ratio, `${state} contrast`).toBeGreaterThanOrEqual(3);
    }
  });

  test("family file is one non-empty line", () => {
    const file = join(dir, "family");
    if (existsSync(file)) expect(read(file)).toMatch(/^[^\s\n][^\n]*\n$/);
  });

  test("pi.json name and appearance agree with the folder and light.mode", () => {
    const pi = JSON.parse(read(dir, "pi.json")) as { name?: string; appearance?: string };
    expect(pi.name).toBe(variant);
    expect(pi.appearance).toBe(isLight(variant) ? "light" : "dark");
  });

  test("pi.json colors resolve to concrete values", () => {
    expect(unresolvedThemeColors(JSON.parse(read(dir, "pi.json")) as ThemeJson)).toEqual([]);
  });

  // helium-theme reloads the extension until its name changes to the variant's.
  test("helium/manifest.json is a theme for this variant", () => {
    const manifest = JSON.parse(read(dir, "helium/manifest.json")) as {
      name?: string;
      theme?: { colors?: Record<string, unknown> };
    };
    expect(manifest.name).toBe(`Theme: ${variant}`);
    const colors = Object.entries(manifest.theme?.colors ?? {});
    expect(colors.length).toBeGreaterThan(0);
    const invalid = colors.filter(
      ([, value]) =>
        !Array.isArray(value) ||
        value.length !== 3 ||
        !value.every((n) => Number.isInteger(n) && n >= 0 && n <= 255),
    );
    expect(invalid).toEqual([]);
  });

  test("tern.json is a complete Oh My Pi theme", () => {
    const tern = JSON.parse(read(dir, "tern.json")) as {
      name?: string;
      vars?: Record<string, string | number>;
      colors: Record<string, string | number>;
    };
    expect(typeof tern.name).toBe("string");
    expect(ompColorTokens.filter((token) => !(token in tern.colors))).toEqual([]);
    expect(unresolvedThemeColors(tern)).toEqual([]);
  });
});

type ThemeJson = {
  vars?: Record<string, string | number>;
  colors: Record<string, string | number>;
  export?: Record<string, string | number>;
};

/** The `export` keys Pi resolves as colors; the rest (backgroundImage, ...) are CSS. */
const exportColorKeys = ["pageBg", "cardBg", "infoBg"];

/**
 * Follows var references the way Pi's resolveVarRefs does: a number, ""
 * (terminal default), a `#` value or an ok(lch|hsl)() value is concrete, and
 * any other string names a var. A bare hex like "C792EA" is therefore a var
 * reference, and Pi rejects the whole theme when that var does not exist.
 * Returns `key: problem` for each color or export color that does not resolve.
 */
function unresolvedThemeColors(theme: ThemeJson): string[] {
  const vars = theme.vars ?? {};
  const resolve = (value: string | number, seen: string[]): string | undefined => {
    if (typeof value === "number" || value === "") return undefined;
    if (value.startsWith("#")) {
      return /^#[0-9a-f]{6}$/i.test(value) ? undefined : `invalid hex ${value}`;
    }
    if (/^ok(lch|hsl)\(/i.test(value)) return undefined;
    if (seen.includes(value)) return `circular reference ${[...seen, value].join(" -> ")}`;
    if (!(value in vars)) return `var not found: ${value}`;
    return resolve(vars[value]!, [...seen, value]);
  };
  const entries = [
    ...Object.entries(theme.colors).map(([key, value]) => [`colors.${key}`, value] as const),
    ...Object.entries(theme.export ?? {})
      .filter(([key]) => exportColorKeys.includes(key))
      .map(([key, value]) => [`export.${key}`, value] as const),
  ];
  return entries.flatMap(([key, value]) => {
    const problem = resolve(value, []);
    return problem ? [`${key}: ${problem}`] : [];
  });
}

test("the hunk mapping names only variants and hunk themes", () => {
  expect([...hunkMapping.keys()].filter((name) => !variants.includes(name))).toEqual([]);
  expect([...hunkMapping.values()].filter((theme) => !hunkThemes.has(theme))).toEqual([]);
});

// lazy.nvim keeps one spec per repo, so a second theme_specs entry for a repo
// would make which entry's options win depend on table order. Variants that
// share a plugin are aliases instead.
test("each Neovim plugin repo has one theme_specs entry", () => {
  const repos = [...themeSpecs.matchAll(/^ {4}repo = '([^']+)',$/gm)].map((match) => match[1]!);
  expect(repos.length).toBe(luaKeys(themeSpecs).length);
  expect(repos.filter((repo, i) => repos.indexOf(repo) !== i)).toEqual([]);
});

test("each Pexels wallpaper is used once and credited in the header", () => {
  const photos = [
    ...externals.matchAll(/^url = "https:\/\/images\.pexels\.com\/photos\/(\d+)\//gm),
  ].map((match) => match[1]!);
  const credited = new Set(
    [...externals.matchAll(/^# .*https:\/\/www\.pexels\.com\/photo\/(\d+)\//gm)].map(
      (match) => match[1]!,
    ),
  );
  expect(photos.filter((photo, i) => photos.indexOf(photo) !== i)).toEqual([]);
  expect(photos.filter((photo) => !credited.has(photo))).toEqual([]);
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
