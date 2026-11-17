// Shared by the action mods in ~/.config/herdr-app/mods: the Herdr app's
// counterparts of the actions in ~/.config/rex/init.lua, so the same keys do
// the same things in both apps.
//
// A key runs `mod.open:<mod>`, which opens the mod as a 1x1 overlay; the mod
// does its work and closes itself. Mods can't import across folders, so
// chezmoi pastes this file into each mod's main.js
// (.chezmoitemplates/herdr-app-action.js). Edit it there.

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

const HOME = home();
const TERMINAL_BROWSER = HOME + "/.local/bin/terminal-browser";
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

// Runs `command` through zsh -c: zsh reads only .zshenv (XDG dirs, EDITOR,
// GIT_OPTIONAL_LOCKS) and skips the login profile, as Rex's popups do with
// login = false. The app's PATH already has Homebrew and the mise shims.
function shell(command) {
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

function isNeopane(name) {
  name = (name ?? "").toLowerCase();
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
  name = (name ?? "").toLowerCase();
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
async function editScrollback(cx) {
  const f = focused();
  if (!f?.terminal) return;
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

async function fileViewer(cx) {
  const f = focused();
  const fg = await foreground(f?.terminal);
  await popup(cx, ["bash", "-c", YAZI, "herdr-yazi", f?.pane ?? ""], fg?.cwd ?? f?.cwd);
}

// Opens the paths yazi chose in a neopane pane of the origin pane's tab
// (preferring the origin), else in a new neopane split to the right of it.
// All of a neopane's panes share one Neovim, so any of them will do: the
// keys reach Normal mode, and <C-M-F12> (nvim config/keymaps.lua) edits the
// files listed in neopane-edit.json.
async function openInNeopane() {
  const text = await readTextFile(CACHE + "/open-in-neopane.json");
  if (!text) return;
  const { pane: origin, paths } = JSON.parse(text);
  if (!paths?.length) return;
  const anchor = panes().find((p) => p.pane === origin) ?? focusedPane();
  const tab = panes().filter((p) => p.tab === anchor?.tab && p.terminal);

  let editor = null;
  for (const p of tab) {
    const fg = await foreground(p.terminal);
    if (isNeopane(fg?.name) && (!editor || p.pane === origin)) editor = p;
  }

  if (editor) {
    await exec("sh", [
      "-c",
      'mkdir -p "$1" && printf "%s" "$2" >"$1/neopane-edit.json"',
      "sh",
      CACHE,
      JSON.stringify(paths),
    ]);
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
  const f = focused();
  if (!f?.terminal) return;
  const fg = await foreground(f.terminal);
  await popup(cx, [PLANNOTATOR, "review", "--target", f.terminal, ...flags], fg?.cwd ?? f.cwd);
}

// `herdr-app-popup`: a command a script asked for, in a popup.
async function popupRequest(cx) {
  const text = await readTextFile(CACHE + "/popup-request.json");
  if (!text) return;
  const { command, cwd } = JSON.parse(text);
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
