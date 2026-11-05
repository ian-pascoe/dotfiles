---
name: aerospace
description: "Control AeroSpace, the user's macOS tiling window manager, through the `aerospace` CLI. Use when the user mentions AeroSpace or asks you to find, focus, move, resize, tile or close windows, or to switch or rearrange workspaces or monitors, on their Mac."
metadata:
  requires-bin: aerospace
  requires-tool: bash|powershell
---

# AeroSpace

AeroSpace tiles every window into named **workspaces**, each shown on one **monitor**. A workspace holds a tree of containers (`h_tiles`, `v_accordion`, …) whose leaves are **windows**; floating windows sit beside the tree. The `aerospace` CLI queries and drives the running server, and accepts the same commands the config binds to keys.

## Check the server

```bash
aerospace list-workspaces --focused
```

It prints the focused workspace's name when the server answers. "Can't connect to AeroSpace server" while `pgrep -x AeroSpace` finds the app means its socket, `/tmp/bobko.aerospace-$USER.sock`, was deleted: ask the user to restart AeroSpace.app, since the CLI cannot reach it until then.

## Learn the CLI

The installed binary is the authority. `aerospace --help` lists the commands; `man aerospace-COMMAND` (for example `man aerospace-list-windows`) documents a command's flags, its `--format` variables and examples. `aerospace COMMAND --help` prints only the synopsis.

Every command acts as soon as it runs, so read syntax from those pages: `aerospace close` run to see what it does closes the user's focused window.

## Target by id

Commands default to the **focused** window or workspace, which is the user's. Target another one explicitly, and focus stays where it is:

- `--window-id ID` on window commands: `move-node-to-workspace`, `move-node-to-monitor`, `move`, `swap`, `join-with`, `resize`, `layout`, `fullscreen`, `close`, and more.
- `--workspace NAME` on workspace commands such as `balance-sizes`, `flatten-workspace-tree` and `layout`.

A command whose man page offers neither flag acts only on the focused node; running it on anything else means moving the user's focus first.

Read ids and state as JSON; `--format` picks the fields, and the keys are the variable names (`window-id`, `app-name`, …):

```bash
aerospace list-windows --all --json --format '%{window-id} %{app-name} %{window-title} %{workspace} %{window-layout}'
aerospace list-workspaces --all --json --format '%{workspace} %{monitor-id} %{workspace-is-focused} %{workspace-is-visible}'
aerospace list-monitors --json
aerospace list-windows --focused --json
```

Match windows by `app-name` or `app-bundle-id` plus `window-title`, and confirm with the user when several match. Your own terminal window cannot be found from your process: your shell usually descends from a multiplexer daemon (Rex, Herdr, Tern), not from the terminal app.

## Arrange windows

```bash
aerospace move-node-to-workspace --window-id ID 3     # focus stays put
aerospace layout --window-id ID floating              # or tiling, h_tiles, v_accordion, …
aerospace resize --window-id ID width +100
aerospace balance-sizes --workspace 3
```

To open an app and place its window: new windows appear on the focused workspace and take focus. Record the focused window id, launch the app (`open -na Ghostty`), poll `list-windows --all --format '%{window-id}'` until a new id appears, move that window with `--window-id`, then hand focus back with `aerospace focus --window-id <recorded-id>`.

`aerospace subscribe EVENT…` streams JSON lines (`focus-changed`, `window-detected`, …) until killed; run it bounded, in a background job you stop.

## Safety

- Focus belongs to the user. `focus`, `workspace`, `summon-workspace`, `move-mouse` and `--focus-follows-window` change what they see and where their keystrokes land; use them when the user asked to be shown something, and restore focus after any focus change you needed.
- Close only windows you opened or the user named: `close` and `close-all-windows-but-current` can discard unsaved work.
- `enable off` stops tiling everywhere, and `mode` swaps the user's keybindings; change them only on request.
- `~/.config/aerospace/aerospace.toml` is chezmoi-managed: edit its source (`chezmoi source-path` on that file), and run `aerospace reload-config` once the change is applied.
