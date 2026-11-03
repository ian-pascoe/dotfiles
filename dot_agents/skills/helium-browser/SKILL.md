---
name: helium-browser
description: Drive the user's running Helium browser, with its logins and open tabs, through agent-browser. Use when a web task needs the user's signed-in sessions, or the user asks to use their browser or Helium.
---

# Helium browser

agent-browser attaches to the running Helium over the Chrome DevTools Protocol. Its own isolated browser is the default for every other web task; reach for Helium only when the task needs the user's sessions.

## Steps

1. Attach a named session pinned to its own tab:

   ```bash
   agent-browser --session NAME --pin-tab connect "$(helium-cdp)"
   ```

   Helium shows an approval prompt for each new session, and `connect` waits up to 20 seconds for it. Tell the user to approve it before you run the command. One session per task keeps it to one prompt.

2. Work through the agent-browser skill, passing `--session NAME` on every command. `--pin-tab` opens a fresh tab, so the user's tabs stay as they were.
3. Finish with `agent-browser --session NAME close`. It detaches and leaves Helium running.

## When helium-cdp fails

It exits non-zero with the reason:

- **Helium is not running**: ask the user to open it.
- **Remote debugging is off**: ask the user to turn it on at `helium://inspect/#remote-debugging`. The setting opens the whole browser to local programs, so the user flips it.

`--auto-connect` cannot find Helium: it looks only in Chrome, Chromium and Brave folders. Use `helium-cdp`.
