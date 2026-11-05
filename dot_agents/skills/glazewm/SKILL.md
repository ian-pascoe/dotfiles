---
name: glazewm
description: "Control GlazeWM, the user's Windows tiling window manager, through the `glazewm` CLI. Use when the user mentions GlazeWM or asks you to find, focus, move, resize, tile or close windows, or to switch or rearrange workspaces or monitors, on their Windows machine."
metadata:
  requires-bin: glazewm
---

# GlazeWM

GlazeWM tiles windows into **workspaces** predefined in its config, each shown on one **monitor**. Every node is a **container** (monitor, workspace, split, window) with a UUID `id`; a workspace's tree of splits ends in windows, and a window is `tiling`, `floating`, `minimized` or `fullscreen`. The `glazewm` CLI queries and drives the running WM over IPC, and accepts the same commands the config binds to keys.

## Check the WM

```bash
glazewm query app-metadata
```

A JSON reply with a version means the WM is running. A connection error means it is not; starting it is the user's call, and both bare `glazewm` and `glazewm start` launch it.

## Learn the CLI

The installed binary is the authority: `glazewm --help`, then `glazewm query --help`, `glazewm command --help` and `glazewm command COMMAND --help` (for example `glazewm command move --help`). Every command acts as soon as it runs, so read syntax from those pages.

Every reply is one JSON object, `{clientMessage, data, error, success}`, and the exit status is 0 even when the command failed: read `success` and `error` after every call. Parse with `jq`, or `ConvertFrom-Json` in PowerShell.

The WM splits the command on whitespace and ignores quotes, so a workspace name, title or path containing a space cannot be passed; the one exception is a double-quoted program path at the start of `shell-exec`.

## Target by id

`glazewm command` acts on the **focused** container, which is the user's. Put `--id UUID` before the command to act on another container, and focus stays where it is:

```bash
glazewm command --id <window-id> move --workspace 3
```

Read ids and state from queries:

```bash
glazewm query windows      # .data.windows[]: id, processName, title, className, handle, state, hasFocus
glazewm query focused      # .data.focused
glazewm query monitors     # the full tree
glazewm query workspaces | jq '.data.workspaces[] | {name, hasFocus, isDisplayed,
  windows: [.. | objects | select(.type == "window") | {id, processName, title}]}'
```

A window carries only its `parentId`; take its workspace from the `query workspaces` tree, as above. Match windows by `processName` plus `title`, and confirm with the user when several match. Your own terminal window cannot be found from your process: your shell usually descends from a multiplexer, not from the terminal window.

## Arrange windows

```bash
glazewm command --id <window-id> move --workspace 3   # focus stays put
glazewm command --id <window-id> toggle-floating
glazewm command --id <window-id> resize --width +10%
glazewm command --id <window-id> set-tiling-direction vertical
```

To open an app and place its window: new windows land on the focused workspace and take focus. Record the focused window id, launch the app (`glazewm command shell-exec PROGRAM`, run by the WM from the home directory with `%VAR%` expanded), poll `query windows` until a new id appears, move that window with `--id`, then hand focus back with `glazewm command focus --container-id <recorded-id>`.

`glazewm sub -e EVENT…` streams JSON lines (`focus_changed`, `window_managed`, …) until killed; run it bounded, in a background job you stop.

## Safety

- Focus belongs to the user. `focus` and the workspace-switching commands change what they see and where their keystrokes land; use them when the user asked to be shown something, and restore focus after any focus change you needed.
- Close only windows you opened or the user named: `close` can discard unsaved work. `ignore` stops managing a window for good.
- `wm-exit` quits the WM, `wm-toggle-pause` suspends it, and `wm-enable-binding-mode` swaps the user's keybindings; run them only on request.
- `%USERPROFILE%\.glzr\glazewm\config.yaml` is chezmoi-managed: edit its source (`chezmoi source-path` on that file), and run `glazewm command wm-reload-config` once the change is applied.
