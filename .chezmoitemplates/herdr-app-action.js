// Shared by the action mods in ~/.config/herdr-app/mods: the Herdr app's
// counterparts of the actions in ~/.config/rex/init.lua, so the same keys do
// the same things in both apps.
//
// A key runs `mod.open:<mod>`, which opens the mod as a 1x1 overlay; the mod
// does its work and closes itself. Mods can't import across folders, so
// chezmoi pastes this file into each mod's main.js
// (.chezmoitemplates/herdr-app-action.js). Edit it there.
//
// chezmoi also fills in the OS below. macOS and Linux run the actions'
// commands through zsh and sh; Windows runs them through PowerShell 7
// (pwsh), opens Neovim where the others open neopane (macOS and Linux only),
// and has no Plannotator review (herdr-app-plannotator is a bash script).

import { View, div } from "gpui-kit";
import {
  props,
  closeOverlay,
  openOverlay,
  focused,
  panes,
  terminals,
  run,
  exec,
  hc,
  home,
  readTextFile,
  checking,
  shared,
  setShared,
  notify,
} from "herdr";

const WINDOWS = "{{ .chezmoi.os }}" === "windows";
const HOME = home();
const TERMINAL_BROWSER = WINDOWS ? "terminal-browser" : HOME + "/.local/bin/terminal-browser";
const PLANNOTATOR = HOME + "/.local/bin/herdr-app-plannotator";
const CACHE = HOME + "/.cache/herdr-app";

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function focusedPane() {
  return panes().find((p) => p.focused) ?? null;
}

// The focused terminal's program, from the app's program table: the program
// running in it now (nvim, lazygit), else what it started with.
function programOf(address) {
  if (!address) return null;
  const pane = panes().find((p) => p.terminal === address);
  return (pane ?? terminals().find((t) => t.address === address))?.program ?? null;
}

// A process name as the matchers below expect it: `nvim`, not `nvim.exe`.
function processName(name) {
  return (name ?? "").toLowerCase().replace(/\.exe$/, "");
}

// The foreground process of a terminal, as `hc get` reports it.
async function foreground(address) {
  if (!address) return null;
  const r = await hc(["get", address, "--json"]);
  try {
    return JSON.parse(r.stdout).foreground ?? null;
  } catch {
    return null;
  }
}

// A PowerShell single-quoted string: nothing in it expands.
function psQuote(s) {
  return "'" + String(s).replace(/'/g, "''") + "'";
}

// Runs a PowerShell script with `args` in $argv. pwsh -Command passes no
// arguments to its script, so they're written into it as literals.
function pwsh(script, args = []) {
  return [
    "pwsh",
    "-NoLogo",
    "-NoProfile",
    "-Command",
    `$argv = @(${args.map(psQuote).join(", ")}); ${script}`,
  ];
}

// Runs `command` through zsh -c: zsh reads only .zshenv (XDG dirs, EDITOR,
// GIT_OPTIONAL_LOCKS, PATH with the mise shims) and skips the login profile,
// as Rex's popups do with login = false. On Windows, through pwsh, which finds
// mise's shims and other .cmd programs on PATH as a shell would.
function shell(command) {
  if (WINDOWS) {
    return pwsh(
      "$rest = @($argv | Select-Object -Skip 1); & $argv[0] @rest; exit $LASTEXITCODE",
      command,
    );
  }
  return ["zsh", "-c", 'exec "$@"', "zsh", ...command];
}

// Starts `command` in a new herdr-core terminal outside every tab; returns
// its address. `rm`: removed once it exits.
async function startTerminal(command, cwd, { rm = true } = {}) {
  const args = ["run", "--bg", "--json", "--no-parent", "--no-notify"];
  if (rm) args.push("--rm");
  if (cwd) args.push("--cwd", cwd);
  args.push("--", ...shell(command));
  const r = await hc(args);
  const out = JSON.parse(r.stdout || "{}");
  if (!out.address) throw new Error(r.stderr || r.stdout || "hc run failed");
  return out.address;
}

// Shows a terminal over the window, as Rex's floating layers do, and gives it
// the keyboard. It closes when the terminal's program exits. `modal`: a
// click beside it doesn't close it (and orphan the program).
async function showTerminal(cx, address, { modal = true } = {}) {
  const overlay = openOverlay({
    kind: "dialog",
    modal,
    width: 0.9,
    height: 0.9,
    layout: { type: "block", content: { terminal: address } },
  });
  // The overlay's terminal block exists only once it has drawn; focusing it
  // sooner fails with "no such pane".
  for (const ms of [120, 250, 500]) {
    await cx.sleep(ms);
    if (focused()?.terminal === address) break;
    run("pane.focus", { terminal: address });
  }
  return overlay;
}

// A popup like Rex's: `command` in a floating terminal over the tab, gone
// when it exits.
async function popup(cx, command, cwd) {
  const address = await startTerminal(command, cwd);
  return showTerminal(cx, address);
}

function neopane(args) {
  // neopane runs on macOS and Linux only: Windows gets a plain Neovim.
  if (WINDOWS) return ["nvim", ...args];
  // mise's link to its newest Neovim first: neopane starts `nvim` from PATH,
  // and the mise shim costs about 80ms a launch.
  return [
    "sh",
    "-c",
    'd="${XDG_DATA_HOME:-$HOME/.local/share}/mise/installs/neovim/latest/bin"; ' +
      '[ -x "$d/nvim" ] && PATH="$d:$PATH"; ' +
      'n="$HOME/.local/bin/neopane"; [ -x "$n" ] || n=neopane; ' +
      'exec "$n" "$@"',
    "neopane",
    ...args,
  ];
}

// The editor neopane() starts, as a terminal's foreground process.
function isNeopane(name) {
  name = processName(name);
  if (WINDOWS) return name === "nvim";
  return name === "neopane" || name === "npane";
}

// ---------------------------------------------------------------------------
// Vim navigation (vim-herdr-navigation)
// ---------------------------------------------------------------------------

// ctrl+h/j/k/l moves between panes. neopane's windows are Herdr app panes, so
// the app moves between them itself. When a plain Vim is in the foreground the
// key goes to Vim instead, which moves between its own splits and, at an edge,
// runs `herdr-app do pane.go` (dot_config/nvim/lua/plugins/util.lua).
// Nested multiplexers get the key too, so they navigate their own panes, and
// so do short-lived TUIs that move their selection with it (fzf, lazygit), as
// HERDR_NAV_PASSTHROUGH_RE does for Herdr.
const PASSTHROUGH = new Set(["herdr", "tmux", "zellij", "fzf", "lazygit"]);
const NAV_KEYS = { left: "ctrl+h", down: "ctrl+j", up: "ctrl+k", right: "ctrl+l" };

// Same matcher as vim-tmux-navigator: ^g?(view|l?n?vim?x?)(diff)?$
function wantsNavKeys(name) {
  name = processName(name);
  if (PASSTHROUGH.has(name)) return true;
  name = name.replace(/^g/, "").replace(/diff$/, "");
  return name === "view" || /^l?n?vim?x?$/.test(name);
}

async function navigate(direction) {
  const f = focused();
  // A shell is the common case: move at once, without asking hc.
  if (f?.terminal && !programOf(f.terminal)?.shell) {
    const fg = await foreground(f.terminal);
    if (fg && wantsNavKeys(fg.name)) {
      await hc(["keys", f.terminal, NAV_KEYS[direction]]);
      return;
    }
  }
  if (f?.pane) run("pane.go", { direction });
}

// ---------------------------------------------------------------------------
// Panes
// ---------------------------------------------------------------------------

// cycle_pane_next / cycle_pane_previous: the shown tab's panes in order.
function cyclePane(by) {
  const f = focused();
  const list = panes().filter((p) => p.tab === f?.tab);
  if (list.length < 2) return;
  const i = list.findIndex((p) => p.focused);
  const next = list[(i + by + list.length) % list.length];
  run("pane.focus", { pane: next.pane });
}

// edit_scrollback: the focused terminal's screen and history in $EDITOR.
// $argv: the terminal.
const SCROLLBACK_PS = `
[Console]::OutputEncoding = [Text.Encoding]::UTF8
$f = Join-Path ([IO.Path]::GetTempPath()) "herdr-scrollback-$([guid]::NewGuid()).txt"
hc read $argv[0] --lines 100000 | Out-File -Encoding utf8 $f
$editor = if ($env:VISUAL) { $env:VISUAL } elseif ($env:EDITOR) { $env:EDITOR } else { 'nvim' }
$words = -split $editor
$rest = @($words | Select-Object -Skip 1)
& $words[0] @rest '+' $f
Remove-Item -Force $f
`;

async function editScrollback(cx) {
  const f = focused();
  if (!f?.terminal) return;
  if (WINDOWS) {
    await popup(cx, pwsh(SCROLLBACK_PS, [f.terminal]), f.cwd);
    return;
  }
  await popup(
    cx,
    [
      "sh",
      "-c",
      'f=$(mktemp "${TMPDIR:-/tmp}/herdr-scrollback.XXXXXX") || exit 1; ' +
        'hc read "$1" --lines 100000 >"$f"; ' +
        '${VISUAL:-${EDITOR:-neopane}} + "$f"; rm -f "$f"',
      "sh",
      f.terminal,
    ],
    f.cwd,
  );
}

// ---------------------------------------------------------------------------
// Commands
// ---------------------------------------------------------------------------

async function neogit(cx) {
  // NeogitPopup (nvim plugins/editor.lua) quits Neovim, and so neopane, when
  // Neogit closes.
  const f = focused();
  const fg = await foreground(f?.terminal);
  await popup(cx, neopane(["+NeogitPopup"]), fg?.cwd ?? f?.cwd);
}

// file_viewer: yazi in a popup. Chosen files open in the tab's neopane pane,
// or a new neopane split beside the pane yazi was opened from: yazi writes
// its choice to a file and quits; the popup then hands it to the
// open-in-neopane mod.
const YAZI = `
chosen=$(mktemp "\${TMPDIR:-/tmp}/herdr-yazi.XXXXXX")
yazi --chooser-file="$chosen"
if [[ -s $chosen ]]; then
  mkdir -p "$HOME/.cache/herdr-app"
  jq -Rn --arg pane "$1" '{pane: $pane, paths: [inputs | select(. != "")]}' <"$chosen" \\
    >"$HOME/.cache/herdr-app/open-in-neopane.json"
  if ! out=$(herdr-app do mod.open --name open-in-neopane 2>&1); then
    printf '\\nCouldn'"'"'t open in neopane: %s\\n\\n' "$out" >&2
    read -rsn1 -p 'Press any key to close'
  fi
fi
rm -f "$chosen"
`;

// The same in PowerShell. $argv: the pane, the cache folder.
const YAZI_PS = `
$chosen = Join-Path ([IO.Path]::GetTempPath()) "herdr-yazi-$([guid]::NewGuid()).txt"
yazi "--chooser-file=$chosen"
if ((Test-Path $chosen) -and (Get-Item $chosen).Length -gt 0) {
  $paths = @(Get-Content -Encoding utf8 $chosen | Where-Object { $_ -ne '' })
  New-Item -ItemType Directory -Force $argv[1] | Out-Null
  ConvertTo-Json -Compress -InputObject @{ pane = $argv[0]; paths = $paths } |
    Set-Content -Encoding utf8 (Join-Path $argv[1] 'open-in-neopane.json')
  $out = herdr-app do mod.open --name open-in-neopane 2>&1
  if ($LASTEXITCODE -ne 0) {
    Write-Host "\`nCouldn't open in Neovim: $out\`n"
    Write-Host -NoNewline 'Press any key to close'
    [void][Console]::ReadKey($true)
  }
}
Remove-Item -Force -ErrorAction SilentlyContinue $chosen
`;

async function fileViewer(cx) {
  const f = focused();
  const fg = await foreground(f?.terminal);
  const command = WINDOWS
    ? pwsh(YAZI_PS, [f?.pane ?? "", CACHE])
    : ["bash", "-c", YAZI, "herdr-yazi", f?.pane ?? ""];
  await popup(cx, command, fg?.cwd ?? f?.cwd);
}

// Reads a JSON file the commands above wrote (PowerShell may add a BOM).
async function readJson(path) {
  const text = await readTextFile(path);
  return text ? JSON.parse(text.replace(/^\uFEFF/, "")) : null;
}

// Opens the paths yazi chose in a neopane pane of the origin pane's tab
// (preferring the origin), else in a new neopane split to the right of it.
// All of a neopane's panes share one Neovim, so any of them will do: the
// keys reach Normal mode, and <C-M-F12> (nvim config/keymaps.lua) edits the
// files listed in neopane-edit.json.
async function openInNeopane() {
  const request = await readJson(CACHE + "/open-in-neopane.json");
  if (!request) return;
  const { pane: origin, paths } = request;
  if (!paths?.length) return;
  const anchor = panes().find((p) => p.pane === origin) ?? focusedPane();
  const tab = panes().filter((p) => p.tab === anchor?.tab && p.terminal);

  let editor = null;
  for (const p of tab) {
    const fg = await foreground(p.terminal);
    if (isNeopane(fg?.name) && (!editor || p.pane === origin)) editor = p;
  }

  if (editor) {
    const [cmd, ...args] = WINDOWS
      ? pwsh(
          "New-Item -ItemType Directory -Force $argv[0] | Out-Null; " +
            "[IO.File]::WriteAllText((Join-Path $argv[0] 'neopane-edit.json'), $argv[1])",
          [CACHE, JSON.stringify(paths)],
        )
      : [
          "sh",
          "-c",
          'mkdir -p "$1" && printf "%s" "$2" >"$1/neopane-edit.json"',
          "sh",
          CACHE,
          JSON.stringify(paths),
        ];
    await exec(cmd, args);
    await hc(["keys", editor.terminal, "ctrl+\\", "ctrl+n", "ctrl+alt+f12"]);
    run("pane.focus", { pane: editor.pane });
    return;
  }

  if (!anchor) return;
  run("pane.split", {
    direction: "right",
    pane: anchor.pane,
    argv: shell(neopane(["--", ...paths])),
  });
}

// ---------------------------------------------------------------------------
// Browser (terminal-browser, https://terminal-browser.com)
// ---------------------------------------------------------------------------

// prefix+w toggles a floating browser over the tab. Hiding it only closes the
// overlay, so the browser keeps its pages; quitting it (ctrl+q) ends it, and
// its overlay with it. One per tab. --no-merge keeps it from opening as a tab
// of another terminal-browser and leaving the overlay empty.
// Modal, so only this toggle hides it and `open` stays true to the screen
// (the app can't list overlays).
async function browser(cx) {
  const f = focused();
  if (!f?.tab) return;
  const all = shared("browser.overlays") ?? {};
  const save = (state) => setShared("browser.overlays", { ...all, [f.tab]: state });
  const mine = all[f.tab];
  const live = mine && terminals().some((t) => t.address === mine.terminal && t.state === "live");

  if (live && mine.open) {
    closeOverlay(mine.overlay);
    save({ ...mine, open: false });
    return;
  }
  let address = live ? mine.terminal : null;
  if (!address) {
    const fg = await foreground(f.terminal);
    address = await startTerminal([TERMINAL_BROWSER, "open", "--no-merge"], fg?.cwd ?? f.cwd, {
      rm: false,
    });
  }
  const overlay = await showTerminal(cx, address);
  save({ terminal: address, overlay, open: true });
}

// ---------------------------------------------------------------------------
// Worktrees: the app's own worktree dialog (settings.json worktrees.directory)
// ---------------------------------------------------------------------------

function worktree(action) {
  const f = focused();
  const size = action === "new" ? { width: 460, height: 280 } : { width: 560, height: 480 };
  openOverlay({
    mod: "worktree",
    kind: "dialog",
    ...size,
    props: { space: f?.space, folder: f?.cwd, action },
  });
}

// ---------------------------------------------------------------------------
// Plannotator (herdr-annotate's document review)
// ---------------------------------------------------------------------------

// plannotator-tui's review in a popup over the focused pane, sending the
// feedback to the agent there (else to the clipboard), as herdr-annotate's
// annotate.* actions do in Herdr. ~/.local/bin/herdr-app-plannotator runs
// plannotator-tui's Herdr pane and stands in for herdr behind it.
async function annotate(cx, flags) {
  if (WINDOWS)
    throw new Error(
      "Plannotator review needs herdr-app-plannotator, a bash script, so it isn't set up on Windows",
    );
  const f = focused();
  if (!f?.terminal) return;
  const fg = await foreground(f.terminal);
  await popup(cx, [PLANNOTATOR, "review", "--target", f.terminal, ...flags], fg?.cwd ?? f.cwd);
}

// `herdr-app-popup`: a command a script asked for, in a popup.
async function popupRequest(cx) {
  const request = await readJson(CACHE + "/popup-request.json");
  if (!request) return;
  const { command, cwd } = request;
  if (command?.length) await popup(cx, command, cwd || null);
}

// ---------------------------------------------------------------------------
// The mod
// ---------------------------------------------------------------------------

const ACTIONS = {
  navigate: (_cx, args) => navigate(args.direction),
  cycle_pane: (_cx, args) => cyclePane(args.by),
  edit_scrollback: editScrollback,
  neogit,
  file_viewer: fileViewer,
  open_in_neopane: openInNeopane,
  browser,
  worktree: (_cx, args) => worktree(args.action),
  annotate: (cx, args) => annotate(cx, args.flags ?? []),
  popup: popupRequest,
};

function failed(name, err) {
  notify({ title: `${name} failed`, body: String(err?.message ?? err), level: "error" });
}

// The mod's class: runs `name` once with `args`, then closes its overlay.
// Each mod's main.js calls it after pasting this file in.
// oxlint-disable-next-line no-unused-vars
function action(name, args = {}) {
  return class Action extends View {
    init(_props, cx) {
      if (checking()) return;
      const overlay = props()?.overlay;
      let result;
      try {
        result = ACTIONS[name](cx, args);
      } catch (err) {
        failed(name, err);
      }
      if (!(result instanceof Promise)) {
        closeOverlay(overlay);
        return;
      }
      cx.spawn(async () => {
        try {
          await result;
        } catch (err) {
          failed(name, err);
        }
        closeOverlay(overlay);
      });
    }

    render() {
      return div();
    }
  };
}
