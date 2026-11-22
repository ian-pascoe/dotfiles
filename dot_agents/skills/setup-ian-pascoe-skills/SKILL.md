---
name: setup-ian-pascoe-skills
description: Configure this repo for Ian Pascoe's skills, checking their prerequisites, recording its code host, and, when it has a UI, capturing its product context with impeccable. Run once per repo, after setup-matt-pocock-skills.
disable-model-invocation: true
---

Configure this repo for the skills from `ian-pascoe/skills`: check their prerequisites, write the repo's **code host config**, `docs/agents/code-host.md`, which `code-host` reads before detecting the host itself, then, when the repo has a UI, capture its product context with `impeccable`'s `init`.

## 1. Check prerequisites

These skills run mattpocock's `grilling`, `research`, `domain-modeling`, `tdd`, `codebase-design`, `code-review`, `pr`, and `writing-for-agents` by name. List any missing from your available skills, and show the user the exact command that installs them at the scope this skill is installed at, adding `-g` when it sits in a user-level skills folder rather than this repo's:

```bash
npx skills@latest add mattpocock/skills --skill <missing skills> [-g] -y
```

Run it once the user agrees; otherwise leave the command with them and carry on.

The repo **has a UI** when it builds something a user sees: web pages, or a desktop or mobile app. Ask the user when the code leaves it unclear. Only then do these skills need pbakaus's `impeccable`, which `validating-ui` and step 4 run, a driver for `validating-ui` (`agent-browser` for web pages and Electron apps, `agent-desktop` for native desktop apps), and `ffmpeg` for its demos. Treat the ones it needs as prerequisites the same way, with the install commands from the `ian-pascoe/skills` README's UI validation section.

Then read `docs/agents/issue-tracker.md`. If it's missing, stop and tell the user to run `/setup-matt-pocock-skills` first, installing it the same way if they lack it, then this again: its tracker doc and `## Agent skills` block are what this skill builds on.

Done when every prerequisite is installed or its command is with the user, and the tracker doc exists.

## 2. Find the code host

Run `code-host`, setting aside any existing code host config so it detects the host afresh. Ask the user about an ambiguous host, recommending the one the existing config names, if any. When the result differs from the existing config, say so. Stop on no remote or a host no reference covers. Missing auth or push access belongs to this machine, not the repo: note it for the report and carry on.

Read which merge methods the repo allows (**Merge methods & merge queue**) and recommend the first it allows of squash, merge commit, and rebase: the order `landing` falls back to without a config. The user may pick another, or none to leave the choice to each run.

Done when you hold the host, its code host reference, its push remote, and a recommended merge method.

## 3. Confirm and write

Show the user drafts of the config and the `## Agent skills` entry.

`docs/agents/code-host.md`, leaving out the merge method line when the user chose none:

```md
# Code host: <host>

- **Reference:** `<reference file>`
- **Push remote:** `<remote>`
- **Merge method:** <squash | merge commit | rebase>
```

A `### Code host` entry in the `## Agent skills` block, in whichever of `CLAUDE.md` or `AGENTS.md` holds it, after `### Issue tracker`:

```md
### Code host

<Host>, via `<remote>`. See `docs/agents/code-host.md`.
```

On a rerun, update the config and the entry in place, keeping the user's edits around them.

Done when both are written as the user confirmed or edited them.

## 4. Capture product context

Skip this step when the repo has no UI. Otherwise run `impeccable`'s `init`. It interviews the user about the product's users, purpose, and constraints, and writes `PRODUCT.md`, which `impeccable`'s `audit` and `critique` read when `validating-ui` runs them; on a rerun it asks only what has gone stale. When `impeccable` isn't installed, leave the step with the user, naming the install command from step 1.

Done when the repo has no UI, `PRODUCT.md` holds the product record the user confirmed, or the step is with the user.

## 5. Report

Tell the user what you wrote, including the files `init` says to commit, any access still missing on this machine, and any prerequisites or steps left with them. `code-host` reads the config from now on, and the landing skills its merge method; the user can edit it directly, or rerun this skill to detect afresh.
