// Theme-variant generator. A variant's colors live in one roles file,
// dot_themes/tools/roles/<variant>.json; `generate` turns it into the per-app files of
// dot_themes/<variant>/ (see ../CONTEXT.md and ../themes.test.ts for what a variant is).
//
//   node dot_themes/tools/new-variant.ts seed <variant> --ghostty "<Bundled Name>" [--mode light|dark] [--family f]
//   node dot_themes/tools/new-variant.ts seed <variant>            # template with terminal colors to fill
//   node dot_themes/tools/new-variant.ts generate <variant> [--force]
//
// Both take --root <repo> (default: the repo this file is in). Node runs the file as
// TypeScript directly, so: no enums, `import type` for types, no dependencies.
import { createHash } from "node:crypto";
import { existsSync, mkdirSync, readdirSync, readFileSync, writeFileSync } from "node:fs";
import { dirname, join, relative, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { parseArgs } from "node:util";

// ---------------------------------------------------------------- schema

export type Mode = "light" | "dark";

/** What Ghostty and Windows Terminal show: the terminal's own colors. */
export interface TerminalColors {
  background: string;
  foreground: string;
  cursor: string;
  cursorText: string;
  selectionBackground: string;
  selectionForeground: string;
  /** ANSI colors 0-15 in order: black red green yellow blue purple cyan white, then bright. */
  palette: string[];
}

/** The semantic roles the app files are mapped from. All `#rrggbb`. */
export interface SemanticColors {
  /** Page and terminal-app background (pi `pageBg`, yazi/k9s text on accents). */
  background: string;
  /** Primary text. */
  text: string;
  /** Raised surface: user messages, bat line highlight, yazi tab/mode backgrounds. */
  panel: string;
  /** Raised surface above `panel` (YASB popups). */
  popup: string;
  /** Selected row / selection background. */
  bgSelect: string;
  /** Tool call pending background (darker than the page on dark themes). */
  bgPending: string;
  /** Tool call error background (a red tint of the page). */
  bgError: string;
  /** Pi `bgUser`, `bgSuccess`, `bgCustom`: default to `panel`. */
  bgUser?: string;
  bgSuccess?: string;
  bgCustom?: string;
  /** Focus color: borders, links, titles, active tabs. */
  accent: string;
  /** Secondary accent: code spans, inline highlights. */
  accent2: string;
  red: string;
  green: string;
  yellow: string;
  orange: string;
  purple: string;
  cyan: string;
  /** Slightly dimmed text (tool output, variables). */
  textSoft: string;
  /** Secondary text, readable on `background`. */
  muted: string;
  /** Faint text: gutter, thinking-off marker. */
  dim: string;
  comment: string;
  /** Dividers in btop and yazi. */
  border: string;
  /** Inactive window borders, pi borders. */
  borderMuted: string;
  synKeyword: string;
  synFunction: string;
  synString: string;
  synNumber: string;
  synType: string;
  synOperator: string;
}

/** bat.tmTheme scopes that have no role above; each defaults as noted. */
export interface BatColors {
  /** constant.language, support.constant, escapes. Default `synNumber`. */
  constant?: string;
  /** Markup tags. Default `synKeyword`. */
  tag?: string;
  /** Attributes and property keys. Default `yellow`. */
  attribute?: string;
  /** Variables. Default `text`. */
  variable?: string;
  /** Function parameters. Default `text`. */
  parameter?: string;
  /** Namespaces and modules. Default `purple`. */
  namespace?: string;
  /** Punctuation and delimiters. Default `synOperator`. */
  punctuation?: string;
  /** Regular expressions. Default `orange`. */
  regexp?: string;
  /** Markdown headings. Default `accent`. */
  heading?: string;
  /** Links. Default `cyan`. */
  link?: string;
  /** Inline code. Default `green`. */
  raw?: string;
  /** Diff inserted / deleted / changed. Default `green` / `red` / `yellow`. */
  inserted?: string;
  deleted?: string;
  changed?: string;
}

export interface Roles {
  mode: Mode;
  /** Family file contents: the light and dark variants of one design share it. */
  family?: string;
  /** Display name: ghostty.conf title, bat theme name, yazi flavor comment. */
  name: string;
  /** ghostty.conf `# Source: <sources>.` */
  sources: string;
  /** `Hand-derived from <derivedFrom>.` headers of the other files. Default `sources`. */
  derivedFrom?: string;
  terminal: TerminalColors;
  colors: SemanticColors;
  bat?: BatColors;
}

const requiredColors = [
  "background",
  "text",
  "panel",
  "popup",
  "bgSelect",
  "bgPending",
  "bgError",
  "accent",
  "accent2",
  "red",
  "green",
  "yellow",
  "orange",
  "purple",
  "cyan",
  "textSoft",
  "muted",
  "dim",
  "comment",
  "border",
  "borderMuted",
  "synKeyword",
  "synFunction",
  "synString",
  "synNumber",
  "synType",
  "synOperator",
] as const;
const optionalColors = ["bgUser", "bgSuccess", "bgCustom"] as const;
const batKeys = [
  "constant",
  "tag",
  "attribute",
  "variable",
  "parameter",
  "namespace",
  "punctuation",
  "regexp",
  "heading",
  "link",
  "raw",
  "inserted",
  "deleted",
  "changed",
] as const;
const terminalKeys = [
  "background",
  "foreground",
  "cursor",
  "cursorText",
  "selectionBackground",
  "selectionForeground",
] as const;

const isHex = (value: unknown): value is string =>
  typeof value === "string" && /^#[0-9a-f]{6}$/i.test(value);

/** Checks a parsed roles file and returns it with every color lowercased. */
export function parseRoles(raw: unknown, source = "roles"): Roles {
  const errors: string[] = [];
  const isObject = (value: unknown): value is Record<string, unknown> =>
    typeof value === "object" && value !== null && !Array.isArray(value);
  if (!isObject(raw)) throw new Error(`${source}: expected a JSON object`);

  const hex = (value: unknown, where: string) => {
    if (isHex(value)) return value.toLowerCase();
    errors.push(
      value === undefined
        ? `${where}: missing`
        : `${where}: expected #rrggbb, got ${JSON.stringify(value)}`,
    );
    return "#000000";
  };
  const group = (value: unknown, where: string, allowed: readonly string[], required: boolean) => {
    if (!isObject(value)) {
      if (required) errors.push(`${where}: missing object`);
      return {};
    }
    for (const key of Object.keys(value)) {
      if (!allowed.includes(key)) errors.push(`${where}.${key}: unknown key`);
    }
    return value;
  };

  if (raw.mode !== "light" && raw.mode !== "dark") errors.push('mode: expected "light" or "dark"');
  const text = (key: string, required: boolean): string | undefined => {
    const value = raw[key];
    if (typeof value === "string" && value.trim() !== "") return value.trim();
    if (value !== undefined || required) errors.push(`${key}: expected non-empty text`);
    return undefined;
  };
  const name = text("name", true);
  const sources = text("sources", true);
  const family = text("family", false);
  const derivedFrom = text("derivedFrom", false);
  if (family && /\s/.test(family)) errors.push("family: expected a single word");

  const terminalRaw = group(raw.terminal, "terminal", [...terminalKeys, "palette"], true);
  const terminal = {} as Record<string, unknown>;
  for (const key of terminalKeys) terminal[key] = hex(terminalRaw[key], `terminal.${key}`);
  const paletteRaw = terminalRaw.palette;
  if (Array.isArray(paletteRaw) && paletteRaw.length === 16) {
    terminal.palette = paletteRaw.map((color, index) => hex(color, `terminal.palette[${index}]`));
  } else {
    errors.push("terminal.palette: expected 16 colors");
    terminal.palette = [];
  }

  const colorsRaw = group(raw.colors, "colors", [...requiredColors, ...optionalColors], true);
  const colors = {} as Record<string, string>;
  for (const key of requiredColors) colors[key] = hex(colorsRaw[key], `colors.${key}`);
  for (const key of optionalColors) {
    if (colorsRaw[key] !== undefined) colors[key] = hex(colorsRaw[key], `colors.${key}`);
  }

  const batRaw = group(raw.bat, "bat", batKeys, false);
  const bat = {} as Record<string, string>;
  for (const key of batKeys)
    if (batRaw[key] !== undefined) bat[key] = hex(batRaw[key], `bat.${key}`);

  if (errors.length > 0) throw new Error(`${source}:\n  ${errors.join("\n  ")}`);
  const roles: Roles = {
    mode: raw.mode as Mode,
    ...(family ? { family } : {}),
    name: name!,
    sources: sources!,
    ...(derivedFrom ? { derivedFrom } : {}),
    terminal: terminal as unknown as TerminalColors,
    colors: colors as unknown as SemanticColors,
    ...(Object.keys(bat).length > 0 ? { bat: bat as BatColors } : {}),
  };
  return roles;
}

// ---------------------------------------------------------------- color math

type Rgb = [number, number, number];

const toRgb = (color: string): Rgb => {
  const value = Number.parseInt(color.slice(1), 16);
  return [(value >> 16) & 255, (value >> 8) & 255, value & 255];
};
const toHex = ([r, g, b]: Rgb) =>
  `#${[r, g, b]
    .map((n) =>
      Math.round(Math.max(0, Math.min(255, n)))
        .toString(16)
        .padStart(2, "0"),
    )
    .join("")}`;

/** `amount` of `b` over `a`. */
export function mix(a: string, b: string, amount: number): string {
  const [x, y] = [toRgb(a), toRgb(b)];
  return toHex(x.map((channel, i) => channel * (1 - amount) + y[i]! * amount) as Rgb);
}

function luminance(color: string): number {
  const [r, g, b] = toRgb(color).map((channel) => {
    const v = channel / 255;
    return v <= 0.03928 ? v / 12.92 : ((v + 0.055) / 1.055) ** 2.4;
  }) as Rgb;
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

export function contrast(a: string, b: string): number {
  const [hi, lo] = [luminance(a), luminance(b)].sort((x, y) => y - x) as [number, number];
  return (hi + 0.05) / (lo + 0.05);
}

/** Moves `color` toward `toward` until it reaches `ratio` contrast on `bg`. */
function readable(color: string, bg: string, toward: string, ratio: number): string {
  for (let step = 0; step <= 20 && contrast(color, bg) < ratio; step++) {
    color = mix(color, toward, 0.05);
  }
  return color;
}

// ---------------------------------------------------------------- templates
// The per-app files are zenbones-dark's, with each color replaced by its role.

/** Every role resolved: the optional ones filled in from their defaults. */
type Colors = Required<SemanticColors>;

const argb = (color: string) => `0xff${color.slice(1)}`;
const triple = (color: string) => toRgb(color).join(", ");

const borders = (c: Colors): string =>
  `export BORDERS_ACTIVE_COLOR=${argb(c.accent)}
export BORDERS_INACTIVE_COLOR=${argb(c.borderMuted)}
`;

const btop = (c: Colors, source: string): string =>
  `# Hand-derived from ${source}.
theme[main_bg]="${c.background}"
theme[main_fg]="${c.text}"
theme[title]="${c.accent}"
theme[hi_fg]="${c.accent}"
theme[selected_bg]="${c.bgSelect}"
theme[selected_fg]="${c.text}"
theme[inactive_fg]="${c.muted}"
theme[graph_text]="${c.cyan}"
theme[meter_bg]="${c.bgSelect}"
theme[proc_misc]="${c.cyan}"
theme[cpu_box]="${c.accent}"
theme[mem_box]="${c.green}"
theme[net_box]="${c.cyan}"
theme[proc_box]="${c.purple}"
theme[div_line]="${c.border}"
theme[temp_start]="${c.green}"
theme[temp_mid]="${c.yellow}"
theme[temp_end]="${c.red}"
theme[cpu_start]="${c.green}"
theme[cpu_mid]="${c.accent}"
theme[cpu_end]="${c.purple}"
theme[free_start]="${c.green}"
theme[free_mid]="${c.yellow}"
theme[free_end]="${c.accent}"
theme[cached_start]="${c.cyan}"
theme[cached_mid]="${c.accent}"
theme[cached_end]="${c.purple}"
theme[available_start]="${c.yellow}"
theme[available_mid]="${c.orange}"
theme[available_end]="${c.red}"
theme[used_start]="${c.green}"
theme[used_mid]="${c.cyan}"
theme[used_end]="${c.accent}"
theme[download_start]="${c.yellow}"
theme[download_mid]="${c.orange}"
theme[download_end]="${c.red}"
theme[upload_start]="${c.green}"
theme[upload_mid]="${c.cyan}"
theme[upload_end]="${c.accent}"
`;

const glazewm = (c: Colors): string =>
  `window_effects:
  focused_window:
    border:
      color: "${c.accent}"
  other_windows:
    border:
      color: "${c.borderMuted}"
`;

const k9s = (c: Colors, source: string): string =>
  `# Hand-derived from ${source}.
k9s:
  body:
    fgColor: "${c.text}"
    bgColor: default
    logoColor: "${c.accent}"
  prompt:
    fgColor: "${c.text}"
    bgColor: default
    suggestColor: "${c.accent}"
  help:
    fgColor: "${c.text}"
    bgColor: default
    sectionColor: "${c.green}"
    keyColor: "${c.accent}"
    numKeyColor: "${c.red}"
  frame:
    title:
      fgColor: "${c.cyan}"
      bgColor: default
      highlightColor: "${c.purple}"
      counterColor: "${c.yellow}"
      filterColor: "${c.green}"
    border:
      fgColor: "${c.accent}"
      focusColor: "${c.accent2}"
    menu:
      fgColor: "${c.text}"
      keyColor: "${c.accent}"
      numKeyColor: "${c.red}"
    crumbs:
      fgColor: "${c.background}"
      bgColor: default
      activeColor: "${c.yellow}"
    status:
      newColor: "${c.accent}"
      modifyColor: "${c.cyan}"
      addColor: "${c.green}"
      pendingColor: "${c.yellow}"
      errorColor: "${c.red}"
      highlightColor: "${c.cyan}"
      killColor: "${c.purple}"
      completedColor: "${c.muted}"
  info:
    fgColor: "${c.yellow}"
    sectionColor: "${c.text}"
  views:
    table:
      fgColor: "${c.text}"
      bgColor: default
      cursorFgColor: "${c.text}"
      cursorBgColor: "${c.bgSelect}"
      markColor: "${c.green}"
      header:
        fgColor: "${c.yellow}"
        bgColor: default
        sorterColor: "${c.cyan}"
    xray:
      fgColor: "${c.text}"
      bgColor: default
      cursorColor: "${c.bgSelect}"
      cursorTextColor: "${c.text}"
      graphicColor: "${c.purple}"
    charts:
      bgColor: default
      chartBgColor: default
      dialBgColor: default
      defaultDialColors:
        - "${c.green}"
        - "${c.red}"
      defaultChartColors:
        - "${c.green}"
        - "${c.red}"
      resourceColors:
        cpu:
          - "${c.accent}"
          - "${c.cyan}"
        mem:
          - "${c.green}"
          - "${c.yellow}"
    yaml:
      keyColor: "${c.accent}"
      valueColor: "${c.text}"
      colonColor: "${c.muted}"
    logs:
      fgColor: "${c.text}"
      bgColor: default
      indicator:
        fgColor: "${c.cyan}"
        bgColor: default
        toggleOnColor: "${c.green}"
        toggleOffColor: "${c.muted}"
  dialog:
    fgColor: "${c.yellow}"
    bgColor: default
    buttonFgColor: "${c.text}"
    buttonBgColor: default
    buttonFocusFgColor: "${c.background}"
    buttonFocusBgColor: "${c.purple}"
    labelFgColor: "${c.yellow}"
    fieldFgColor: "${c.text}"
`;

const lsd = (c: Colors, source: string): string =>
  `# Hand-derived from ${source}.
user: "${c.accent}"
group: "${c.cyan}"
permission:
  read: "${c.green}"
  write: "${c.yellow}"
  exec: "${c.red}"
  exec-sticky: "${c.purple}"
  no-access: "${c.muted}"
  octal: "${c.cyan}"
  acl: "${c.cyan}"
  context: "${c.accent}"
date:
  hour-old: "${c.green}"
  day-old: "${c.accent}"
  older: "${c.muted}"
size:
  none: "${c.muted}"
  small: "${c.green}"
  medium: "${c.yellow}"
  large: "${c.orange}"
inode:
  valid: "${c.purple}"
  invalid: "${c.muted}"
links:
  valid: "${c.cyan}"
  invalid: "${c.muted}"
tree-edge: "${c.dim}"
git-status:
  default: "${c.text}"
  unmodified: "${c.muted}"
  ignored: "${c.muted}"
  new-in-index: "${c.green}"
  new-in-workdir: "${c.green}"
  typechange: "${c.yellow}"
  deleted: "${c.red}"
  renamed: "${c.accent}"
  modified: "${c.yellow}"
  conflicted: "${c.red}"
`;

const yaziFlavor = (c: Colors, name: string): string =>
  `# ${name} local Yazi flavor

[mgr]
cwd = { fg = "${c.accent}" }
find_keyword = { fg = "${c.yellow}", bold = true, italic = true }
find_position = { fg = "${c.purple}", bg = "reset", bold = true, italic = true }
marker_copied = { fg = "${c.green}", bg = "${c.green}" }
marker_cut = { fg = "${c.red}", bg = "${c.red}" }
marker_marked = { fg = "${c.accent2}", bg = "${c.accent2}" }
marker_selected = { fg = "${c.yellow}", bg = "${c.yellow}" }
count_copied = { fg = "${c.background}", bg = "${c.green}" }
count_cut = { fg = "${c.background}", bg = "${c.red}" }
count_selected = { fg = "${c.background}", bg = "${c.yellow}" }
border_symbol = "│"
border_style = { fg = "${c.border}" }

[tabs]
active = { fg = "${c.background}", bg = "${c.accent}", bold = true }
inactive = { fg = "${c.accent}", bg = "${c.panel}" }

[mode]
normal_main = { fg = "${c.background}", bg = "${c.accent}", bold = true }
normal_alt = { fg = "${c.accent}", bg = "${c.panel}" }
select_main = { fg = "${c.background}", bg = "${c.green}", bold = true }
select_alt = { fg = "${c.green}", bg = "${c.panel}" }
unset_main = { fg = "${c.background}", bg = "${c.purple}", bold = true }
unset_alt = { fg = "${c.purple}", bg = "${c.panel}" }

[status]
perm_sep = { fg = "${c.border}" }
perm_type = { fg = "${c.accent}" }
perm_read = { fg = "${c.green}" }
perm_write = { fg = "${c.yellow}" }
perm_exec = { fg = "${c.red}" }
progress_label = { fg = "${c.text}", bold = true }
progress_normal = { fg = "${c.green}", bg = "${c.bgSelect}" }
progress_error = { fg = "${c.background}", bg = "${c.red}" }

[pick]
border = { fg = "${c.accent}" }
active = { fg = "${c.purple}", bold = true }
inactive = {}

[input]
border = { fg = "${c.accent}" }
title = {}
value = {}
selected = { reversed = true }

[cmp]
border = { fg = "${c.accent}" }

[tasks]
border = { fg = "${c.accent}" }
title = {}
hovered = { fg = "${c.purple}", bold = true }

[which]
border = { fg = "${c.accent}" }
cand = { fg = "${c.accent2}" }
rest = { fg = "${c.muted}" }
desc = { fg = "${c.purple}" }
separator = "  "
separator_style = { fg = "${c.border}" }

[help]
on = { fg = "${c.accent2}" }
run = { fg = "${c.purple}" }
hovered = { reversed = true, bold = true }
footer = { fg = "${c.background}", bg = "${c.text}" }

[spot]
border = { fg = "${c.accent}" }
title = { fg = "${c.accent}" }
tbl_col = { fg = "${c.accent2}" }
tbl_cell = { fg = "${c.purple}", bg = "${c.bgSelect}" }

[notify]
title_info = { fg = "${c.green}" }
title_warn = { fg = "${c.yellow}" }
title_error = { fg = "${c.red}" }

[filetype]
rules = [
  { mime = "**/image/*", fg = "${c.cyan}" },
  { mime = "**/{audio,video}/*", fg = "${c.yellow}" },
  { mime = "**/application/{zip,rar,7z*,tar,gzip,xz,zstd,bzip*,lzma,compress,archive,cpio,arj,xar,ms-cab*}", fg = "${c.purple}" },
  { mime = "**/application/{pdf,doc,rtf}", fg = "${c.green}" },
  { mime = "vfs/{absent,stale}", fg = "${c.muted}" },
  { url = "*", fg = "${c.text}" },
  { url = "*/", fg = "${c.accent}" },
]
`;

const yasb = (c: Colors, name: string, source: string): string => `:root {
  /* ${name} palette (hand-derived from ${source}); values are RGB triples for YASB's rgb(var(--token)) usage. */
  --background: ${triple(c.background)};
  --foreground: ${triple(c.text)};
  --card-background: ${triple(c.panel)};
  --popup-background: ${triple(c.popup)};
  --primary: ${triple(c.accent)};
  --secondary: ${triple(c.accent2)};
  --tertiary: ${triple(c.accent)};
  --accent: ${triple(c.purple)};
  --muted-background: ${triple(c.muted)};
  --info: ${triple(c.accent)};
  --success: ${triple(c.green)};
  --warning: ${triple(c.yellow)};
  --destructive: ${triple(c.red)};
  --border: ${triple(c.borderMuted)};
  --text: ${triple(c.text)};
  --foam: ${triple(c.cyan)};
  --gold: ${triple(c.yellow)};
  --love: ${triple(c.red)};
  --overlay: ${triple(c.muted)};
  --highlight: ${triple(c.bgSelect)};

  --card-foreground: var(--foreground);
  --popup-foreground: var(--foreground);
  --primary-foreground: var(--background);
  --secondary-foreground: var(--background);
  --tertiary-foreground: var(--background);
  --accent-foreground: var(--background);
  --muted-foreground: var(--background);
  --info-foreground: var(--background);
  --success-foreground: var(--background);
  --warning-foreground: var(--background);
  --destructive-foreground: var(--background);

  --background-image: none;
}
`;

const yaziTheme = (variant: string): string =>
  `[flavor]\nlight = "${variant}"\ndark = "${variant}"\n`;

const yaziLink = (variant: string): string =>
  `{{ if ne .chezmoi.os "windows" -}}\n{{ joinPath .chezmoi.homeDir ".themes/${variant}/yazi/flavors/${variant}.yazi" }}\n{{ end -}}\n`;

// A version-5 UUID of the variant name, so regenerating keeps bat's uuid stable.
function uuidFor(variant: string): string {
  const dns = Buffer.from("6ba7b8109dad11d180b400c04fd430c8", "hex");
  const hash = createHash("sha1").update(dns).update(`${variant}.theme.dotfiles`).digest();
  hash[6] = (hash[6]! & 0x0f) | 0x50;
  hash[8] = (hash[8]! & 0x3f) | 0x80;
  const hexString = hash.subarray(0, 16).toString("hex");
  return [0, 8, 12, 16, 20]
    .map((start, i, all) => hexString.slice(start, all[i + 1] ?? 32))
    .join("-");
}

const escapeXml = (text: string) =>
  text.replaceAll("&", "&amp;").replaceAll("<", "&lt;").replaceAll(">", "&gt;");

function batTheme(variant: string, roles: Roles, c: Colors, source: string): string {
  const b = roles.bat ?? {};
  const color = {
    constant: b.constant ?? c.synNumber,
    tag: b.tag ?? c.synKeyword,
    attribute: b.attribute ?? c.yellow,
    variable: b.variable ?? c.text,
    parameter: b.parameter ?? c.text,
    namespace: b.namespace ?? c.purple,
    punctuation: b.punctuation ?? c.synOperator,
    regexp: b.regexp ?? c.orange,
    heading: b.heading ?? c.accent,
    link: b.link ?? c.cyan,
    raw: b.raw ?? c.green,
    inserted: b.inserted ?? c.green,
    deleted: b.deleted ?? c.red,
    changed: b.changed ?? c.yellow,
  };
  const row = (scope: string, foreground: string, fontStyle?: string) =>
    `      <dict><key>scope</key><string>${scope}</string><key>settings</key><dict><key>foreground</key><string>${foreground.toUpperCase()}</string>${
      fontStyle ? `<key>fontStyle</key><string>${fontStyle}</string>` : ""
    }</dict></dict>`;
  const rows = [
    row("comment, punctuation.definition.comment", c.comment, "italic"),
    row("string, punctuation.definition.string", c.synString),
    row("constant.numeric, keyword.other.unit", c.synNumber),
    row(
      "constant.language, support.constant, variable.other.constant, constant.character.escape",
      color.constant,
    ),
    row("keyword, storage.type, storage.modifier, keyword.control", c.synKeyword),
    row(
      "entity.name.function, support.function, variable.function, meta.function-call",
      c.synFunction,
    ),
    row("entity.name.type, support.type, entity.name.class, support.class", c.synType),
    row("entity.name.tag, punctuation.definition.tag", color.tag),
    row(
      "entity.other.attribute-name, support.type.property-name, meta.object-literal.key, variable.other.property",
      color.attribute,
    ),
    row("variable, variable.other.readwrite", color.variable),
    row("variable.parameter, meta.function.parameters", color.parameter),
    row("entity.name.namespace, entity.name.module", color.namespace),
    row("keyword.operator", c.synOperator),
    row("punctuation, meta.delimiter", color.punctuation),
    row("string.regexp", color.regexp),
    row("markup.heading, markup.heading entity.name", color.heading, "bold"),
    row("markup.bold", c.text, "bold"),
    row("markup.italic", c.text, "italic"),
    row("markup.raw, markup.inline.raw", color.raw),
    row("markup.underline.link, string.other.link", color.link),
    row("markup.inserted, markup.inserted.diff", color.inserted),
    row("markup.deleted, markup.deleted.diff", color.deleted),
    row("markup.changed, markup.changed.diff", color.changed),
    row("invalid", c.red, "underline"),
  ];
  return `<?xml version="1.0" encoding="UTF-8"?>
<!-- Hand-derived from ${escapeXml(source).replaceAll("--", "- -")}. -->
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <dict>
    <key>name</key>
    <string>${escapeXml(roles.name)}</string>
    <key>semanticClass</key>
    <string>theme.${roles.mode}.${variant}</string>
    <key>uuid</key>
    <string>${uuidFor(variant)}</string>
    <key>settings</key>
    <array>
      <dict>
        <key>settings</key>
        <dict>
          <key>background</key><string>${c.background.toUpperCase()}</string>
          <key>foreground</key><string>${c.text.toUpperCase()}</string>
          <key>caret</key><string>${roles.terminal.cursor.toUpperCase()}</string>
          <key>lineHighlight</key><string>${c.panel.toUpperCase()}</string>
          <key>selection</key><string>${c.bgSelect.toUpperCase()}</string>
          <key>gutterForeground</key><string>${c.dim.toUpperCase()}</string>
        </dict>
      </dict>
${rows.join("\n")}
    </array>
  </dict>
</plist>
`;
}

function ghosttyConf(roles: Roles): string {
  const t = roles.terminal;
  return [
    `# ${roles.name}`,
    "# Inline colors keep this theme independent of Ghostty's installed theme catalog.",
    `# Source: ${stripPeriod(roles.sources)}.`,
    `background = ${t.background}`,
    `foreground = ${t.foreground}`,
    `cursor-color = ${t.cursor}`,
    `cursor-text = ${t.cursorText}`,
    `selection-background = ${t.selectionBackground}`,
    `selection-foreground = ${t.selectionForeground}`,
    ...t.palette.map((color, index) => `palette = ${index}=${color}`),
    "",
  ].join("\n");
}

const json = (value: unknown) => `${JSON.stringify(value, null, 2)}\n`;

/** pi.json vars, and the `colors` map that references them (see the Oh My Pi token list). */
function piParts(c: Colors) {
  const vars = {
    accent: c.accent,
    accent2: c.accent2,
    green: c.green,
    red: c.red,
    yellow: c.yellow,
    orange: c.orange,
    purple: c.purple,
    cyan: c.cyan,
    textSoft: c.textSoft,
    muted: c.muted,
    dim: c.dim,
    comment: c.comment,
    borderMuted: c.borderMuted,
    bgSelect: c.bgSelect,
    bgUser: c.bgUser,
    bgPending: c.bgPending,
    bgSuccess: c.bgSuccess,
    bgError: c.bgError,
    bgCustom: c.bgCustom,
    pageBg: c.background,
    synKeyword: c.synKeyword,
    synFunction: c.synFunction,
    synString: c.synString,
    synNumber: c.synNumber,
    synType: c.synType,
    synOperator: c.synOperator,
  };
  const colors: Record<string, string> = {
    accent: "accent",
    border: "accent",
    borderAccent: "accent2",
    borderMuted: "borderMuted",
    success: "green",
    error: "red",
    warning: "yellow",
    muted: "muted",
    dim: "dim",
    text: "",
    thinkingText: "muted",
    selectedBg: "bgSelect",
    userMessageBg: "bgUser",
    userMessageText: "textSoft",
    customMessageBg: "bgCustom",
    customMessageText: "textSoft",
    customMessageLabel: "purple",
    toolPendingBg: "bgPending",
    toolSuccessBg: "bgSuccess",
    toolErrorBg: "bgError",
    toolTitle: "accent",
    toolOutput: "textSoft",
    mdHeading: "orange",
    mdLink: "accent",
    mdLinkUrl: "muted",
    mdCode: "accent2",
    mdCodeBlock: "green",
    mdCodeBlockBorder: "borderMuted",
    mdQuote: "muted",
    mdQuoteBorder: "borderMuted",
    mdHr: "borderMuted",
    mdListBullet: "purple",
    toolDiffAdded: "green",
    toolDiffRemoved: "red",
    toolDiffContext: "muted",
    syntaxComment: "comment",
    syntaxKeyword: "synKeyword",
    syntaxFunction: "synFunction",
    syntaxVariable: "textSoft",
    syntaxString: "synString",
    syntaxNumber: "synNumber",
    syntaxType: "synType",
    syntaxOperator: "synOperator",
    syntaxPunctuation: "muted",
    thinkingOff: "borderMuted",
    thinkingMinimal: "dim",
    thinkingLow: "accent2",
    thinkingMedium: "accent",
    thinkingHigh: "purple",
    thinkingXhigh: "red",
    bashMode: "green",
  };
  const exported = { pageBg: c.background, cardBg: c.panel, infoBg: c.bgSelect };
  return { vars, colors, exported };
}

function piJson(variant: string, roles: Roles, c: Colors): string {
  const { vars, colors, exported } = piParts(c);
  return json({
    $schema: "https://pi.dev/schemas/theme.schema.json",
    name: variant,
    appearance: roles.mode,
    vars,
    colors,
    export: exported,
  });
}

function ternJson(variant: string, roles: Roles, c: Colors): string {
  const { vars, colors, exported } = piParts(c);
  const statusLine = {
    statusLineBg: "bgSelect",
    statusLineSep: "borderMuted",
    statusLineModel: "purple",
    statusLinePath: "accent",
    statusLineGitClean: "green",
    statusLineGitDirty: "yellow",
    statusLineContext: "muted",
    statusLineSpend: "accent2",
    statusLineStaged: "green",
    statusLineDirty: "yellow",
    statusLineUntracked: "accent",
    statusLineOutput: "textSoft",
    statusLineCost: "textSoft",
    statusLineSubagents: "accent",
    pythonMode: "yellow",
  };
  return json({
    name: variant,
    vars,
    colors: { ...colors, ...statusLine },
    export: exported,
    terminal: {
      background: roles.terminal.background,
      foreground: roles.terminal.foreground,
      chrome: roles.terminal.background,
      widget: roles.terminal.background,
      ansi: roles.terminal.palette,
    },
  });
}

const stripPeriod = (text: string) => text.trim().replace(/\.$/, "");

// ---------------------------------------------------------------- Windows Terminal

const ansiNames = ["black", "red", "green", "yellow", "blue", "purple", "cyan", "white"] as const;

/** Windows Terminal color scheme, keys in the alphabetical order settings.json keeps. */
function windowsScheme(variant: string, roles: Roles): Record<string, string> {
  const t = roles.terminal;
  const scheme: Record<string, string> = {
    background: t.background,
    foreground: t.foreground,
    cursorColor: t.cursor,
    selectionBackground: t.selectionBackground,
    name: variant,
  };
  ansiNames.forEach((color, index) => {
    scheme[color] = t.palette[index]!;
    scheme[`bright${color[0]!.toUpperCase()}${color.slice(1)}`] = t.palette[index + 8]!;
  });
  return Object.fromEntries(
    Object.entries(scheme)
      .sort(([a], [b]) => (a < b ? -1 : 1))
      .map(([key, value]) => [key, key === "name" ? value : value.toUpperCase()]),
  );
}

function windowsTheme(variant: string, roles: Roles, c: Colors) {
  const light = roles.mode === "light";
  return {
    name: variant,
    tab: {
      background: `${c.background.toUpperCase()}FF`,
      iconStyle: "default",
      showCloseButton: "always",
      unfocusedBackground: null,
    },
    tabRow: {
      background: `${(light ? c.panel : c.popup).toUpperCase()}FF`,
      unfocusedBackground: `${(light ? c.bgSelect : c.bgPending).toUpperCase()}FF`,
    },
    window: {
      applicationTheme: roles.mode,
      "experimental.rainbowFrame": false,
      frame: null,
      unfocusedFrame: null,
      useMica: false,
    },
  };
}

export type Upsert = "inserted" | "replaced" | "unchanged";

function upsertByName(list: { name?: string }[], entry: { name: string }): Upsert {
  const index = list.findIndex((item) => item.name === entry.name);
  if (index === -1) {
    list.push(entry);
    return "inserted";
  }
  if (JSON.stringify(list[index]) === JSON.stringify(entry)) return "unchanged";
  list[index] = entry;
  return "replaced";
}

/**
 * Inserts or replaces (by name) the variant's scheme and theme in Windows Terminal's
 * settings.json. The file is rewritten as 2-space JSON, which is how it is kept, so only
 * the variant's entries change; a file in any other shape is refused rather than reflowed.
 */
export function upsertWindowsTerminal(
  file: string,
  variant: string,
  roles: Roles,
  c: Colors = resolveColors(roles),
): { scheme: Upsert; theme: Upsert } {
  const text = readFileSync(file, "utf8");
  const settings = JSON.parse(text) as {
    schemes?: { name: string }[];
    themes?: { name: string }[];
  };
  if (json(settings) !== text) {
    throw new Error(`${file} is not 2-space JSON as JSON.stringify writes it; format it first`);
  }
  settings.schemes ??= [];
  settings.themes ??= [];
  const result = {
    scheme: upsertByName(settings.schemes, windowsScheme(variant, roles) as { name: string }),
    theme: upsertByName(settings.themes, windowsTheme(variant, roles, c)),
  };
  if (result.scheme !== "unchanged" || result.theme !== "unchanged") {
    writeFileSync(file, json(settings));
  }
  return result;
}

// ---------------------------------------------------------------- generate

function resolveColors(roles: Roles): Colors {
  const { colors } = roles;
  return {
    ...colors,
    bgUser: colors.bgUser ?? colors.panel,
    bgSuccess: colors.bgSuccess ?? colors.panel,
    bgCustom: colors.bgCustom ?? colors.panel,
  };
}

/** The variant's files as paths relative to the repo root. */
export function renderVariant(variant: string, roles: Roles): Map<string, string> {
  const c = resolveColors(roles);
  const source = stripPeriod(roles.derivedFrom ?? roles.sources);
  const dir = `dot_themes/${variant}`;
  const files = new Map<string, string>([
    [`${dir}/bat.tmTheme`, batTheme(variant, roles, c, source)],
    [`${dir}/borders.sh`, borders(c)],
    [`${dir}/btop.theme`, btop(c, source)],
    [`${dir}/ghostty.conf`, ghosttyConf(roles)],
    [`${dir}/glazewm.yaml`, glazewm(c)],
    [`${dir}/k9s.yaml`, k9s(c, source)],
    [`${dir}/lsd.yaml`, lsd(c, source)],
    [`${dir}/pi.json`, piJson(variant, roles, c)],
    [`${dir}/tern.json`, ternJson(variant, roles, c)],
    [`${dir}/yasb.css`, yasb(c, roles.name, source)],
    [`${dir}/yazi/theme.toml`, yaziTheme(variant)],
    [`${dir}/yazi/flavors/${variant}.yazi/flavor.toml`, yaziFlavor(c, roles.name)],
    [`dot_config/yazi/flavors/symlink_${variant}.yazi.tmpl`, yaziLink(variant)],
  ]);
  if (roles.mode === "light") files.set(`${dir}/empty_light.mode`, "");
  if (roles.family) files.set(`${dir}/family`, `${roles.family}\n`);
  return files;
}

export const windowsTerminalFile = "dot_config/windows-terminal/settings.json";
const rolesPath = (root: string, variant: string) =>
  join(root, "dot_themes/tools/roles", `${variant}.json`);

const variantPattern = /^[a-z0-9]+(?:-[a-z0-9]+)*$/;
function checkVariant(variant: string | undefined): string {
  if (!variant || !variantPattern.test(variant)) {
    throw new Error(
      `variant must be a lowercase folder name like "tokyo-night-storm", got ${JSON.stringify(variant)}`,
    );
  }
  return variant;
}

export interface FileResult {
  path: string;
  status: "written" | "skipped" | "unchanged";
}

export interface GenerateResult {
  files: FileResult[];
  /** Absent when the root has no Windows Terminal settings.json. */
  windowsTerminal?: { scheme: Upsert; theme: Upsert };
  warnings: string[];
}

export function generate(
  variant: string,
  options: { root: string; force?: boolean },
): GenerateResult {
  checkVariant(variant);
  const { root, force = false } = options;
  const file = rolesPath(root, variant);
  if (!existsSync(file)) throw new Error(`no roles file ${file}; run \`seed ${variant}\` first`);
  const roles = parseRoles(JSON.parse(readFileSync(file, "utf8")), file);
  const warnings: string[] = [];
  if (/^todo/i.test(roles.sources.trim())) warnings.push(`sources in ${file} is still a TODO`);

  const files: FileResult[] = [];
  for (const [path, content] of renderVariant(variant, roles)) {
    const absolute = join(root, path);
    let status: FileResult["status"] = "written";
    if (existsSync(absolute)) {
      if (readFileSync(absolute, "utf8") === content) status = "unchanged";
      else if (!force) status = "skipped";
    }
    if (status === "written") {
      mkdirSync(dirname(absolute), { recursive: true });
      writeFileSync(absolute, content);
    }
    files.push({ path, status });
  }

  const settings = join(root, windowsTerminalFile);
  if (!existsSync(settings))
    warnings.push(`${windowsTerminalFile} not found; Windows Terminal skipped`);
  const windowsTerminal = existsSync(settings)
    ? upsertWindowsTerminal(settings, variant, roles)
    : undefined;
  return { files, ...(windowsTerminal ? { windowsTerminal } : {}), warnings };
}

// ---------------------------------------------------------------- seed

export const bundledGhosttyThemes = "/Applications/Ghostty.app/Contents/Resources/ghostty/themes";

/** Reads a Ghostty theme file (`key = value` lines, `palette = N=#hex`). */
export function parseGhosttyTheme(text: string, source = "theme"): TerminalColors {
  const keyed = new Map<string, string>();
  const palette: string[] = [];
  for (const line of text.split("\n")) {
    const match = /^\s*([a-z-]+)\s*=\s*(.*?)\s*$/.exec(line);
    if (!match) continue;
    const [, key, value] = match as unknown as [string, string, string];
    const normalize = (color: string) => {
      const withHash = /^[0-9a-f]{6}$/i.test(color) ? `#${color}` : color;
      if (!isHex(withHash))
        throw new Error(`${source}: cannot read color ${JSON.stringify(color)}`);
      return withHash.toLowerCase();
    };
    if (key === "palette") {
      const entry = /^(\d+)\s*=\s*(\S+)$/.exec(value);
      if (entry) palette[Number(entry[1])] = normalize(entry[2]!);
    } else {
      keyed.set(key, value);
    }
  }
  const color = (key: string): string | undefined => {
    const value = keyed.get(key);
    if (value === undefined) return undefined;
    return /^[0-9a-f]{6}$/i.test(value) ? `#${value.toLowerCase()}` : value.toLowerCase();
  };
  const background = color("background");
  const foreground = color("foreground");
  if (!isHex(background) || !isHex(foreground))
    throw new Error(`${source}: no background/foreground`);
  if (palette.length !== 16 || palette.some((entry) => !entry)) {
    throw new Error(`${source}: expected palette entries 0-15`);
  }
  const pick = (key: string, fallback: string) => {
    const value = color(key);
    return isHex(value) ? value : fallback;
  };
  return {
    background,
    foreground,
    cursor: pick("cursor-color", foreground),
    cursorText: pick("cursor-text", background),
    selectionBackground: pick("selection-background", mix(background, foreground, 0.2)),
    selectionForeground: pick("selection-foreground", foreground),
    palette,
  };
}

/** Finds a bundled theme by name, ignoring case, spaces and punctuation ("Tokyo Night" finds TokyoNight). */
function findGhosttyTheme(dir: string, name: string): string {
  if (!existsSync(dir)) throw new Error(`Ghostty themes folder not found: ${dir}`);
  const entries = readdirSync(dir);
  const simple = (text: string) => text.toLowerCase().replaceAll(/[^a-z0-9]/g, "");
  const found =
    entries.find((entry) => entry === name) ??
    entries.find((entry) => entry.toLowerCase() === name.toLowerCase()) ??
    entries.find((entry) => simple(entry) === simple(name));
  if (found) return found;
  const close = entries
    .filter((entry) => simple(entry).includes(simple(name).slice(0, 5)))
    .slice(0, 8);
  throw new Error(
    `no bundled Ghostty theme "${name}" in ${dir}` +
      (close.length > 0 ? `; close matches: ${close.join(", ")}` : ""),
  );
}

/** Starting semantic roles from a terminal palette: ANSI colors for accents, blends for the rest. */
export function deriveColors(t: TerminalColors, mode: Mode): SemanticColors {
  const { background: bg, foreground: fg, palette } = t;
  const dark = mode === "dark";
  const accent = (color: string) => readable(color, bg, fg, 3.5);
  const yellow = accent(palette[3]!);
  const red = accent(palette[1]!);
  const purple = accent(palette[5]!);
  const cyan = accent(palette[6]!);
  const green = accent(palette[2]!);
  const blue = accent(palette[4]!);
  // Selection must be a subtle tint of the page (it is a background); light themes whose
  // terminal selection is dark-on-light (GitHub Light) get an accent tint instead.
  const bgSelect =
    contrast(t.selectionBackground, bg) < 3 ? t.selectionBackground : mix(bg, blue, 0.15);
  return {
    background: bg,
    text: fg,
    panel: mix(bg, fg, dark ? 0.05 : 0.04),
    popup: mix(bg, fg, dark ? 0.1 : 0.07),
    bgSelect: contrast(bgSelect, bg) < 1.1 ? mix(bg, fg, 0.15) : bgSelect,
    bgPending: dark ? mix(bg, "#000000", 0.3) : mix(bg, fg, 0.08),
    bgError: mix(bg, red, dark ? 0.16 : 0.1),
    accent: blue,
    accent2: accent(palette[14]!),
    red,
    green,
    yellow,
    orange: accent(mix(yellow, red, 0.5)),
    purple,
    cyan,
    textSoft: mix(fg, bg, 0.2),
    muted: readable(mix(bg, fg, 0.55), bg, fg, 4),
    dim: mix(bg, fg, 0.4),
    comment: mix(bg, fg, 0.45),
    border: mix(bg, fg, 0.2),
    borderMuted: mix(bg, fg, 0.14),
    synKeyword: purple,
    synFunction: blue,
    synString: green,
    synNumber: accent(mix(yellow, red, 0.5)),
    synType: yellow,
    synOperator: cyan,
  };
}

// Terminal colors to start from when there is no Ghostty theme to copy.
const placeholderTerminal: Record<Mode, TerminalColors> = {
  dark: {
    background: "#1c1c1c",
    foreground: "#d0d0d0",
    cursor: "#d0d0d0",
    cursorText: "#1c1c1c",
    selectionBackground: "#3a3a3a",
    selectionForeground: "#d0d0d0",
    palette: [
      "#1c1c1c",
      "#e06c75",
      "#98c379",
      "#e5c07b",
      "#61afef",
      "#c678dd",
      "#56b6c2",
      "#d0d0d0",
      "#5c6370",
      "#e88b93",
      "#abd18f",
      "#ecd093",
      "#82c0f4",
      "#d298e4",
      "#78c8d3",
      "#ffffff",
    ],
  },
  light: {
    background: "#fafafa",
    foreground: "#383a42",
    cursor: "#383a42",
    cursorText: "#fafafa",
    selectionBackground: "#e2e4ea",
    selectionForeground: "#383a42",
    palette: [
      "#383a42",
      "#ca1243",
      "#2d7d3a",
      "#986801",
      "#0b5fcc",
      "#a626a4",
      "#0a7c8c",
      "#a0a1a7",
      "#696c77",
      "#d63d63",
      "#3f9a4c",
      "#b07d1b",
      "#3a7ee0",
      "#b84ab6",
      "#2a96a6",
      "#fafafa",
    ],
  },
};

const titleCase = (variant: string) =>
  variant
    .split("-")
    .map((word) => word[0]!.toUpperCase() + word.slice(1))
    .join(" ");

export interface SeedOptions {
  root: string;
  /** Bundled Ghostty theme name; without it the roles file is a template. */
  ghostty?: string;
  ghosttyDir?: string;
  mode?: Mode;
  family?: string;
  force?: boolean;
}

export function seed(variant: string, options: SeedOptions): { path: string; notes: string[] } {
  checkVariant(variant);
  const { root, ghostty, mode: requestedMode, family, force = false } = options;
  const path = rolesPath(root, variant);
  if (existsSync(path) && !force) {
    throw new Error(`${path} already exists; pass --force to overwrite it`);
  }
  const notes: string[] = [];
  let terminal: TerminalColors;
  let sources = "TODO: where these terminal colors come from";
  let mode = requestedMode;
  if (ghostty) {
    const dir = options.ghosttyDir ?? bundledGhosttyThemes;
    const bundled = findGhosttyTheme(dir, ghostty);
    if (bundled !== ghostty)
      notes.push(`matched bundled Ghostty theme "${bundled}" for "${ghostty}"`);
    terminal = parseGhosttyTheme(readFileSync(join(dir, bundled), "utf8"), join(dir, bundled));
    sources = `Ghostty's bundled "${bundled}" theme`;
    mode ??= luminance(terminal.background) > 0.4 ? "light" : "dark";
  } else {
    mode ??= "dark";
    terminal = placeholderTerminal[mode];
    notes.push("template: fill in terminal colors and sources, then tune colors");
  }
  const roles: Roles = {
    mode,
    ...(family ? { family } : {}),
    name: titleCase(variant),
    sources,
    terminal,
    colors: deriveColors(terminal, mode),
  };
  parseRoles(roles, "seeded roles");
  mkdirSync(dirname(path), { recursive: true });
  writeFileSync(path, json(roles));
  return { path, notes };
}

// ---------------------------------------------------------------- CLI

const usage = `Usage:
  node dot_themes/tools/new-variant.ts seed <variant> [--ghostty "<Bundled Name>"] [--mode light|dark] [--family <name>] [--force]
  node dot_themes/tools/new-variant.ts generate <variant> [--force]

Options for both: --root <repo> (default: the repo containing this file).
seed also takes --ghostty-dir <dir> (default: Ghostty's bundled themes).
`;

const defaultRoot = resolve(dirname(fileURLToPath(import.meta.url)), "../..");

export function remainingSteps(variant: string): string[] {
  return [
    `Remaining by hand (not generated):`,
    `  1. Neovim: add a theme_specs entry, or an alias in the pairs({...}) table, for "${variant}" in dot_config/nvim/lua/plugins/colorscheme.lua`,
    `  2. Hunk: add a \`${variant})\` case line to the hunk theme mapping in dot_config/shell/interactive.sh (not needed if "${variant}" is itself a Shiki theme)`,
    `  3. Wallpaper: add [".themes/${variant}/backgrounds/background-1.jpg"] and its credit line to .chezmoiexternal.toml.tmpl, or put the image in dot_themes/${variant}/backgrounds/`,
  ];
}

export interface Io {
  out: (line: string) => void;
  err: (line: string) => void;
}

/** Runs the CLI; returns the exit code. */
export function main(argv: string[], io: Io = { out: console.log, err: console.error }): number {
  try {
    const { values, positionals } = parseArgs({
      args: argv,
      allowPositionals: true,
      options: {
        ghostty: { type: "string" },
        "ghostty-dir": { type: "string" },
        mode: { type: "string" },
        family: { type: "string" },
        force: { type: "boolean" },
        root: { type: "string" },
        help: { type: "boolean", short: "h" },
      },
    });
    const [command, variant, ...extra] = positionals;
    if (values.help || !command || extra.length > 0) {
      io.out(usage);
      return values.help ? 0 : 1;
    }
    const root = resolve(values.root ?? defaultRoot);
    const name = checkVariant(variant);

    if (command === "seed") {
      if (values.mode !== undefined && values.mode !== "light" && values.mode !== "dark") {
        throw new Error(`--mode must be light or dark, got ${values.mode}`);
      }
      const result = seed(name, {
        root,
        ghostty: values.ghostty,
        ghosttyDir: values["ghostty-dir"],
        mode: values.mode as Mode | undefined,
        family: values.family,
        force: values.force,
      });
      for (const note of result.notes) io.out(note);
      io.out(`wrote ${relative(root, result.path)}`);
      io.out(
        "Tune the semantic colors (and name, sources), then: " +
          `node dot_themes/tools/new-variant.ts generate ${name}`,
      );
      return 0;
    }

    if (command === "generate") {
      const result = generate(name, { root, force: values.force });
      for (const { path, status } of result.files) {
        io.out(`${status.padEnd(9)} ${path}`);
      }
      if (result.windowsTerminal) {
        io.out(
          `windows-terminal: scheme ${result.windowsTerminal.scheme}, theme ${result.windowsTerminal.theme}`,
        );
      }
      for (const warning of result.warnings) io.out(`warning: ${warning}`);
      if (result.files.some((file) => file.status === "skipped")) {
        io.out("Skipped files exist already; pass --force to overwrite them.");
      }
      for (const line of remainingSteps(name)) io.out(line);
      return 0;
    }
    throw new Error(`unknown command ${JSON.stringify(command)}`);
  } catch (error) {
    io.err(`error: ${error instanceof Error ? error.message : String(error)}`);
    return 1;
  }
}

if (import.meta.main) process.exitCode = main(process.argv.slice(2));
