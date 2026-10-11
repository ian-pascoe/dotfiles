---
name: tern
description: "Control Tern, Stencil's multiplexing terminal, through the `tern` CLI: list, create, rename and kill sessions, split blocks, run commands in another block, read a block's screen, send keys, open files beside the shell. Use when the user mentions Tern or asks to inspect or control Tern sessions, tabs or blocks."
---

# Tern

Tern keeps **sessions** in a per-user daemon. A session holds **tabs**; a tab holds **blocks** (panes running a shell, a program, a file or a browser). The `tern` CLI scripts them, and every open window follows live.

## Locate yourself

Inside a Tern block, `$TERN_PANE` is your own block id:

```bash
test -n "${TERN_PANE:-}" && echo "$TERN_PANE"
```

When it is empty you are outside Tern, and commands act on the first window's sessions. Confirm with the user before changing anything from there.

The installed binary is the authority for syntax: `tern help`, then `tern COMMAND --help` (for example `tern send --help`). Skip `tern help dev`: it covers Tern's own development harness.

## Address blocks by id

Commands take `BLOCK` as an id, `@focused`, a title or a program name, optionally scoped as `SESSION/BLOCK`. Use ids:

- Titles change as programs run (a shell's title becomes the running command), so a title that matched a moment ago may not match now.
- `@focused` is the user's focused block, which is usually not yours.
- Tab names do not address blocks, and `tern rename BLOCK NAME` renames the block's **tab**. `tern rename SESSION NAME` renames a session.

Read ids and state from JSON. Every mutating command takes `--json` and answers with the ids it created (`{"session", "tab", "block"}`):

```bash
tern ls --json          # sessions > tabs > blocks: id, title, cwd, command, exited, keep_open, focused
tern inspect            # the same plus every connected client
tern process BLOCK --json   # the block's child and its foreground process
```

## Run a command and get its result

Run it as the program of a new block, kept open so its output survives, then wait for its exit status:

```bash
B=$(tern split "$TERN_PANE" right --cwd "$PWD" --keep-open --json -- just test | jq -r .block)
tern wait "$B" --timeout 600; echo "exit=$?"
tern capture "$B" --scrollback
```

Block lifecycle:

- A block whose program exits 0 closes, and its output goes with it, unless it was started with `--keep-open` (or switched with `tern keep-open BLOCK on`). A block whose program fails stays, showing `exited: N`.
- `tern wait BLOCK` (default `--until exit`) exits with the program's status, even after the block closed itself; 124 means the timeout ran out.
- New blocks leave focus where it was, and `tern new session` does not change what the window shows.
- Close what you opened when done: `tern close BLOCK`.

Choose `split` direction from the caller's size in `tern ls --json` (`cols`, `rows`): `right` for a wide block, `down` for a tall or narrow one.

## Drive an existing shell or program

Check what is in the foreground first; `tern run` types into whatever owns the terminal:

```bash
tern process BLOCK          # "front" is the foreground process
tern run BLOCK 'cargo build'   # types the command and Enter
tern send BLOCK text 'partial'   # types without Enter
tern send BLOCK keys ctrl+c      # key combos; also enter, esc, tab, arrows
tern send BLOCK paste "$TEXT"    # a bracketed paste, for multi-line input
tern capture BLOCK [--scrollback] [--ansi]
```

An unknown key name fails with exit 1. Use `--ansi` when colours are evidence; plain text otherwise.

Knowing when a command typed into a shell has finished takes care:

- `tern wait --until prompt` relies on the shell reporting its prompt through shell integration. Custom prompts may not report it, and the wait then runs out its timeout.
- `tern wait --until idle=MS` returns after MS milliseconds without output, while a quiet command (a `sleep`, a slow build step) is still running.
- Reliable: end the command line with a sentinel and poll `tern capture` until it appears, for example `tern run "$B" 'make; echo "__done:$?"'`. Better still, run the work as its own block, as above.

## Other surfaces

- `tern open [--preview] PATH[:LINE[:COL]]` shows a file in a file block beside yours, for the user to read. `--wait` blocks until it closes.
- `tern events [--filter KIND,...]` streams JSON lines (`{"event": "title_changed", "pane": …}`, client joins and leaves) until interrupted. Run it under `timeout`.
- `tern browser JSON` drives a browser block; its `--help` documents the ops.
- Agents run as ordinary block programs. Tern has no agent-state API, so drive them with `send` and read them with `capture`.

## Safety

- Change only blocks and sessions you created, unless the user named them.
- `tern kill session SESSION` ends every program in it, editors with unsaved changes included.
- `tern focus BLOCK` moves every window to that block; use it only when the user asks to be shown something.
- Leave `tern daemon` alone: it keeps every session's programs alive.
