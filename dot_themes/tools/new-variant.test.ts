// new-variant.ts writes theme variants from roles files. These tests point it at a
// temporary repo root (its `root` option) so the real dot_themes/ is never touched.
import { existsSync, mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { afterEach, beforeEach, describe, expect, test } from "vitest";
import {
  contrast,
  deriveColors,
  generate,
  main,
  parseGhosttyTheme,
  parseRoles,
  seed,
  upsertWindowsTerminal,
  windowsTerminalFile,
  type Mode,
  type Roles,
  type TerminalColors,
} from "./new-variant";

const themes = dirname(dirname(fileURLToPath(import.meta.url)));

// The Oh My Pi token list lives in themes.test.ts; read it from there so the two agree.
const ompColorTokens = (() => {
  const source = readFileSync(join(themes, "themes.test.ts"), "utf8");
  const list = /const ompColorTokens = `([^`]*)`/.exec(source)?.[1] ?? "";
  return list.split(/\s+/).filter(Boolean);
})();

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

const terminals: Record<Mode, TerminalColors> = {
  dark: {
    background: "#1a1b26",
    foreground: "#c0caf5",
    cursor: "#c0caf5",
    cursorText: "#15161e",
    selectionBackground: "#33467c",
    selectionForeground: "#c0caf5",
    palette: [
      "#15161e",
      "#f7768e",
      "#9ece6a",
      "#e0af68",
      "#7aa2f7",
      "#bb9af7",
      "#7dcfff",
      "#a9b1d6",
      "#414868",
      "#f7768e",
      "#9ece6a",
      "#e0af68",
      "#7aa2f7",
      "#bb9af7",
      "#7dcfff",
      "#c0caf5",
    ],
  },
  light: {
    background: "#ffffff",
    foreground: "#1f2328",
    cursor: "#0969da",
    cursorText: "#ffffff",
    selectionBackground: "#ddf4ff",
    selectionForeground: "#1f2328",
    palette: [
      "#24292f",
      "#cf222e",
      "#116329",
      "#4d2d00",
      "#0969da",
      "#8250df",
      "#1b7c83",
      "#6e7781",
      "#57606a",
      "#a40e26",
      "#1a7f37",
      "#633c01",
      "#218bff",
      "#a475f9",
      "#3192aa",
      "#8c959f",
    ],
  },
};

function fixture(mode: Mode, family?: string): Roles {
  return {
    mode,
    ...(family ? { family } : {}),
    name: mode === "dark" ? "Fixture Dark" : "Fixture Light",
    sources: `the fixture ${mode} palette`,
    terminal: terminals[mode],
    colors: deriveColors(terminals[mode], mode),
  };
}

let root: string;

const write = (path: string, content: string) => {
  mkdirSync(dirname(join(root, path)), { recursive: true });
  writeFileSync(join(root, path), content);
};
const read = (path: string) => readFileSync(join(root, path), "utf8");
const writeRoles = (variant: string, roles: unknown) =>
  write(`dot_themes/tools/roles/${variant}.json`, `${JSON.stringify(roles, null, 2)}\n`);
const emptySettings = () =>
  write(
    windowsTerminalFile,
    `${JSON.stringify({ schemes: [], themes: [], theme: "x" }, null, 2)}\n`,
  );
const settings = () =>
  JSON.parse(read(windowsTerminalFile)) as {
    schemes: { name: string; background: string }[];
    themes: { name: string; window: { applicationTheme: string } }[];
  };

beforeEach(() => {
  root = mkdtempSync(join(tmpdir(), "new-variant-"));
  emptySettings();
});
afterEach(() => rmSync(root, { recursive: true, force: true }));

describe.each([["dark"], ["light"]] as const)("generate (%s)", (mode) => {
  const variant = `fixture-${mode}`;
  const dir = `dot_themes/${variant}`;

  beforeEach(() => {
    writeRoles(variant, fixture(mode, "fixture"));
    generate(variant, { root });
  });

  test.each(requiredFiles)("writes %s", (file) => {
    expect(existsSync(join(root, dir, file))).toBe(true);
  });

  test("writes the yazi flavor and its link", () => {
    expect(read(`${dir}/yazi/theme.toml`)).toContain(`light = "${variant}"`);
    expect(read(`${dir}/yazi/flavors/${variant}.yazi/flavor.toml`)).toContain("[mgr]");
    expect(read(`dot_config/yazi/flavors/symlink_${variant}.yazi.tmpl`)).toContain(
      `.themes/${variant}/yazi/flavors/${variant}.yazi`,
    );
  });

  test("writes a Helium theme whose toolbar is the background", () => {
    const manifest = JSON.parse(read(`${dir}/helium/manifest.json`)) as {
      name: string;
      theme: { colors: Record<string, number[]> };
    };
    expect(manifest.name).toBe(`Theme: ${variant}`);
    const hex = `#${manifest.theme.colors.toolbar!.map((n) => n.toString(16).padStart(2, "0")).join("")}`;
    expect(hex).toBe(terminals[mode].background);
  });

  test("light.mode only for light variants", () => {
    expect(existsSync(join(root, dir, "empty_light.mode"))).toBe(mode === "light");
  });

  test("family file holds the family name", () => {
    expect(read(`${dir}/family`)).toBe("fixture\n");
  });

  test("pi.json is named for the variant and has the appearance", () => {
    const pi = JSON.parse(read(`${dir}/pi.json`)) as { name: string; appearance: string };
    expect(pi.name).toBe(variant);
    expect(pi.appearance).toBe(mode);
  });

  test("tern.json is a complete Oh My Pi theme", () => {
    expect(ompColorTokens.length).toBeGreaterThan(40);
    const tern = JSON.parse(read(`${dir}/tern.json`)) as {
      name: string;
      vars: Record<string, string>;
      colors: Record<string, string>;
      terminal: { ansi: string[] };
    };
    expect(tern.name).toBe(variant);
    expect(ompColorTokens.filter((token) => !(token in tern.colors))).toEqual([]);
    const unresolved = Object.entries(tern.colors).filter(
      ([, value]) => value !== "" && !/^#[0-9a-f]{6}$/i.test(value) && !(value in tern.vars),
    );
    expect(unresolved).toEqual([]);
    expect(tern.terminal.ansi).toHaveLength(16);
  });

  test("ghostty.conf has inline colors and 16 palette entries", () => {
    const conf = read(`${dir}/ghostty.conf`);
    expect(conf).not.toMatch(/^\s*theme\s*=/m);
    expect(conf).toMatch(/^# Source: the fixture \w+ palette\.$/m);
    expect(conf).toMatch(/^background\s*=\s*#[0-9a-f]{6}$/m);
    const palette = [...conf.matchAll(/^palette\s*=\s*(\d+)=#[0-9a-f]{6}$/gm)].map((m) =>
      Number(m[1]),
    );
    expect(palette).toEqual(Array.from({ length: 16 }, (_, i) => i));
  });

  test("bat.tmTheme names the variant", () => {
    const bat = read(`${dir}/bat.tmTheme`);
    expect(bat).toContain(`<string>theme.${mode}.${variant}</string>`);
    expect(bat).toMatch(/<string>[0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12}<\/string>/);
  });

  test("inserts a Windows Terminal scheme and theme", () => {
    expect(settings().schemes.map((scheme) => scheme.name)).toEqual([variant]);
    expect(settings().themes.map((theme) => theme.name)).toEqual([variant]);
    expect(settings().themes[0]!.window.applicationTheme).toBe(mode);
  });
});

describe("variants without a family", () => {
  test("write no family file", () => {
    writeRoles("solo", fixture("dark"));
    generate("solo", { root });
    expect(existsSync(join(root, "dot_themes/solo/family"))).toBe(false);
  });
});

describe("existing files", () => {
  beforeEach(() => writeRoles("kept", fixture("dark")));

  test("are kept and reported without --force", () => {
    write("dot_themes/kept/bat.tmTheme", "upstream");
    const result = generate("kept", { root });
    expect(read("dot_themes/kept/bat.tmTheme")).toBe("upstream");
    expect(result.files.find((file) => file.path.endsWith("bat.tmTheme"))?.status).toBe("skipped");
    expect(result.files.find((file) => file.path.endsWith("pi.json"))?.status).toBe("written");
  });

  test("are replaced with --force", () => {
    write("dot_themes/kept/bat.tmTheme", "upstream");
    generate("kept", { root, force: true });
    expect(read("dot_themes/kept/bat.tmTheme")).toContain("<plist");
  });

  test("a second run changes nothing", () => {
    generate("kept", { root });
    const second = generate("kept", { root });
    expect(second.files.every((file) => file.status === "unchanged")).toBe(true);
    expect(second.windowsTerminal).toEqual({ scheme: "unchanged", theme: "unchanged" });
  });
});

describe("Windows Terminal settings", () => {
  test("replaces the variant's entries by name, leaving others alone, idempotently", () => {
    writeRoles("one", fixture("dark"));
    writeRoles("two", fixture("light"));
    expect(generate("one", { root }).windowsTerminal).toEqual({
      scheme: "inserted",
      theme: "inserted",
    });
    generate("two", { root });
    const before = read(windowsTerminalFile);
    expect(settings().schemes.map((scheme) => scheme.name)).toEqual(["one", "two"]);

    // Same roles: byte-identical file.
    generate("one", { root });
    expect(read(windowsTerminalFile)).toBe(before);

    // Changed roles: "one" replaced in place, "two" untouched.
    const roles = fixture("dark");
    roles.terminal.background = "#101010";
    roles.colors.background = "#101010";
    writeRoles("one", roles);
    expect(generate("one", { root }).windowsTerminal).toEqual({
      scheme: "replaced",
      theme: "replaced",
    });
    expect(settings().schemes.map((scheme) => scheme.name)).toEqual(["one", "two"]);
    expect(settings().schemes[0]!.background).toBe("#101010");
    expect(settings().themes.map((theme) => theme.name)).toEqual(["one", "two"]);
    expect(read(windowsTerminalFile)).toBe(`${JSON.stringify(settings(), null, 2)}\n`);
  });

  test("the generated scheme has the keys of the existing entries", () => {
    writeRoles("keys", fixture("dark"));
    generate("keys", { root });
    expect(Object.keys(settings().schemes[0]!)).toEqual([
      "background",
      "black",
      "blue",
      "brightBlack",
      "brightBlue",
      "brightCyan",
      "brightGreen",
      "brightPurple",
      "brightRed",
      "brightWhite",
      "brightYellow",
      "cursorColor",
      "cyan",
      "foreground",
      "green",
      "name",
      "purple",
      "red",
      "selectionBackground",
      "white",
      "yellow",
    ]);
  });

  test("a root without settings.json skips it with a warning", () => {
    rmSync(join(root, windowsTerminalFile));
    writeRoles("nowt", fixture("dark"));
    const result = generate("nowt", { root });
    expect(result.windowsTerminal).toBeUndefined();
    expect(result.warnings.join("\n")).toContain("Windows Terminal skipped");
  });

  test("refuses a file that is not canonical 2-space JSON", () => {
    write(windowsTerminalFile, '{"schemes":[],"themes":[]}');
    expect(() =>
      upsertWindowsTerminal(join(root, windowsTerminalFile), "x", fixture("dark")),
    ).toThrow(/2-space JSON/);
  });
});

describe("roles files", () => {
  test("accept the fixture and lowercase colors", () => {
    const roles = fixture("dark");
    roles.colors.accent = "#AABBCC";
    expect(parseRoles(roles).colors.accent).toBe("#aabbcc");
  });

  test("report every problem at once", () => {
    const roles = JSON.parse(JSON.stringify(fixture("dark"))) as Record<string, any>;
    roles.mode = "dim";
    roles.colors.accent = "blue";
    roles.colors.accentt = "#000000";
    delete roles.colors.red;
    roles.terminal.palette.pop();
    let message = "";
    try {
      parseRoles(roles, "bad.json");
    } catch (error) {
      message = String(error);
    }
    expect(message).toContain("bad.json");
    expect(message).toContain("mode:");
    expect(message).toContain("colors.accent: expected #rrggbb");
    expect(message).toContain("colors.accentt: unknown key");
    expect(message).toContain("colors.red: missing");
    expect(message).toContain("terminal.palette: expected 16 colors");
  });

  test("generate names the missing roles file", () => {
    expect(() => generate("nothing", { root })).toThrow(/seed nothing/);
  });
});

describe("seed", () => {
  const ghosttyDir = () => join(root, "ghostty-themes");
  const writeTheme = (name: string, theme: TerminalColors) =>
    write(
      `ghostty-themes/${name}`,
      [
        ...theme.palette.map((color, index) => `palette = ${index}=${color}`),
        `background = ${theme.background}`,
        `foreground = ${theme.foreground}`,
        `cursor-color = ${theme.cursor}`,
        `cursor-text = ${theme.cursorText}`,
        `selection-background = ${theme.selectionBackground}`,
        `selection-foreground = ${theme.selectionForeground}`,
        "",
      ].join("\n"),
    );

  test("copies a bundled theme and derives roles, finding it ignoring spaces and case", () => {
    writeTheme("TokyoNight", terminals.dark);
    const result = seed("new-one", { root, ghostty: "Tokyo Night", ghosttyDir: ghosttyDir() });
    expect(result.notes.join("\n")).toContain('"TokyoNight"');
    const roles = parseRoles(JSON.parse(read("dot_themes/tools/roles/new-one.json")));
    expect(roles.mode).toBe("dark");
    expect(roles.name).toBe("New One");
    expect(roles.sources).toBe(`Ghostty's bundled "TokyoNight" theme`);
    expect(roles.terminal).toEqual(terminals.dark);
    expect(roles.colors.accent).toBe(terminals.dark.palette[4]);
    // seeded roles generate a complete variant
    generate("new-one", { root });
    expect(existsSync(join(root, "dot_themes/new-one/tern.json"))).toBe(true);
  });

  test("infers light mode, takes --mode and --family, and keeps accents readable", () => {
    writeTheme("Pale", terminals.light);
    seed("pale", { root, ghostty: "Pale", ghosttyDir: ghosttyDir(), family: "pale-family" });
    const roles = parseRoles(JSON.parse(read("dot_themes/tools/roles/pale.json")));
    expect(roles.mode).toBe("light");
    expect(roles.family).toBe("pale-family");
    for (const key of ["accent", "red", "green", "orange", "muted"] as const) {
      expect(contrast(roles.colors[key], roles.colors.background), key).toBeGreaterThanOrEqual(3.5);
    }
    // light theme with a dark selection (GitHub Light) gets a light selection tint
    writeTheme("Inverted", { ...terminals.light, selectionBackground: "#1f2328" });
    seed("inverted", { root, ghostty: "Inverted", ghosttyDir: ghosttyDir() });
    const inverted = parseRoles(JSON.parse(read("dot_themes/tools/roles/inverted.json")));
    expect(inverted.terminal.selectionBackground).toBe("#1f2328");
    expect(contrast(inverted.colors.bgSelect, inverted.colors.background)).toBeLessThan(3);

    writeTheme("Forced", terminals.dark);
    seed("forced", { root, ghostty: "Forced", ghosttyDir: ghosttyDir(), mode: "light" });
    expect(parseRoles(JSON.parse(read("dot_themes/tools/roles/forced.json"))).mode).toBe("light");
  });

  test("without --ghostty writes a template", () => {
    const result = seed("blank", { root, mode: "light" });
    expect(result.notes.join("\n")).toContain("template");
    const roles = parseRoles(JSON.parse(read("dot_themes/tools/roles/blank.json")));
    expect(roles.mode).toBe("light");
    expect(roles.sources).toMatch(/^TODO/);
    expect(generate("blank", { root }).warnings.join("\n")).toContain("TODO");
  });

  test("refuses to overwrite a roles file without --force", () => {
    seed("twice", { root });
    expect(() => seed("twice", { root })).toThrow(/--force/);
    expect(() => seed("twice", { root, force: true })).not.toThrow();
  });

  test("names close matches for an unknown Ghostty theme", () => {
    writeTheme("Solarized Dark", terminals.dark);
    expect(() =>
      seed("nope", { root, ghostty: "Solarized Lite", ghosttyDir: ghosttyDir() }),
    ).toThrow(/Solarized Dark/);
  });

  test("reads Ghostty colors written without a leading #, with optional keys missing", () => {
    const text = [
      ...Array.from({ length: 16 }, (_, i) => `palette = ${i}=${String(i).padStart(2, "0")}aabb`),
      "background = 101010",
      "foreground = EEEEEE",
    ].join("\n");
    const theme = parseGhosttyTheme(text);
    expect(theme.palette[3]).toBe("#03aabb");
    expect(theme.cursor).toBe("#eeeeee");
    expect(theme.cursorText).toBe("#101010");
    expect(theme.selectionForeground).toBe("#eeeeee");
  });
});

describe("main", () => {
  const run = (...args: string[]) => {
    const out: string[] = [];
    const err: string[] = [];
    const code = main([...args, "--root", root], {
      out: (line) => out.push(line),
      err: (line) => err.push(line),
    });
    return { code, out: out.join("\n"), err: err.join("\n") };
  };

  test("seed then generate, reminding of the manual steps", () => {
    expect(run("seed", "cli-variant").code).toBe(0);
    const result = run("generate", "cli-variant");
    expect(result.code).toBe(0);
    expect(result.out).toContain("dot_config/nvim/lua/plugins/colorscheme.lua");
    expect(result.out).toContain("dot_config/shell/interactive.sh");
    expect(result.out).toContain(".chezmoiexternal.toml.tmpl");
    expect(result.out).toContain("windows-terminal: scheme inserted, theme inserted");
  });

  test("reports skipped files", () => {
    run("seed", "cli-skip");
    write("dot_themes/cli-skip/ghostty.conf", "upstream\n");
    const result = run("generate", "cli-skip");
    expect(result.out).toMatch(/skipped\s+dot_themes\/cli-skip\/ghostty\.conf/);
    expect(result.out).toContain("--force");
  });

  test("errors exit non-zero", () => {
    expect(run("generate", "Bad Name").code).toBe(1);
    expect(run("generate", "missing").err).toContain("seed missing");
    expect(run("frobnicate", "x").err).toContain("unknown command");
    expect(run("seed", "x", "--mode", "grey").err).toContain("--mode");
    expect(run().code).toBe(1);
  });
});
