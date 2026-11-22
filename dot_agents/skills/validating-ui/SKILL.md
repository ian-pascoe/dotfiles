---
name: validating-ui
description: Validate a change's UI by auditing and critiquing it with impeccable, fixing what's worth fixing, then capturing before-and-after screenshots and a demo. Use when a change touches what users see, or when another skill names it.
---

Validate the UI a change touches: run each **surface** it changes at the fixed point and at its head, have `impeccable`'s `audit` and `critique` review the head in subagents, fix the **UI findings** worth fixing, then capture **evidence**, screenshots of the base and the head and a **demo** of the change working, and hand it all back. Drive web pages with `agent-browser` and desktop apps with `agent-desktop`. Decide under `escalating-to-user`; each skill holds except where this one overrides it.

The caller passes the **fixed point**, the change's spec, and its friction log if it keeps one, adding each moment this run fights its environment to that log. Run alone, the fixed point is the default branch and the spec is the plan settled in the conversation, or the PR's `## Plan`.

## 1. Find the surfaces

A **surface** is one place a user sees: a page, screen, window, or component, in the state that shows it, such as its data, auth, theme, or open panel. Trace every file in the diff from the fixed point that renders (markup, styles, tokens, assets, copy) to the surfaces that show it, including the states the change adds, such as empty, loading, and error.

Done when every changed file that renders maps to a surface, or to a reason it shows nowhere. With no surface, report that no UI changed and stop.

## 2. Run the base and the head

Pick a **driver** for each surface, loading its guide from its CLI before its first command:

- a web page, or a desktop app on Electron: `agent-browser` (`agent-browser skills get core`, and `agent-browser skills get electron` for Electron).
- a native desktop app: `agent-desktop` (`agent-desktop skills get platform`). One that renders through a web view without CDP, such as Tauri on macOS or Linux, `impeccable` reviews from source only, as its `audit` and `critique` say. One built on a non-web toolkit, such as AppKit, WPF, GTK, or Qt, `impeccable` has no path for: it skips step 3, and the hand back names the skip.
- a native mobile app: no driver; `impeccable` reviews it from source, on its native path.

A missing prerequisite skips only the part that needs it: without `impeccable`, step 3; without a surface's driver, that surface runs as unrendered; without `ffmpeg`, the demos. Name each in the hand back with its install command from the `ian-pascoe/skills` README's UI validation section, and log it.

Run the head in the current checkout and the base in a temporary worktree at the merge base with the fixed point, each started the way the repo starts it (its scripts, README, or `AGENTS.md`): in the background, its log teed to a file, with a recorded way to stop it. Take a free port and your own driver session, since other runs may share the machine. Seed the same state in both. A surface the change adds has no base.

A surface you can't run is **unrendered**: `impeccable` reviews it from source, its base comes from committed visual-regression goldens or screenshot fixtures where the repo has them, and you log it.

Done when each surface runs at its head, and at its base unless it is new, or is unrendered with the reason.

## 3. Audit and critique

Run `impeccable`'s `audit`, then its `critique`, each in a fresh subagent, so neither sees the other's findings. Brief each with the working directory, the `impeccable` skill's path and the command to run, each surface's source paths and, where `impeccable` can reach it, its live URL or CDP target at the head, and the sizes it ships at. Neither saves a report or asks the user anything: `audit` skips Save the Report and Recommended Actions; `critique` skips Persist the Snapshot and Ask the User, ending with `Questions skipped: run by validating-ui`, and spawns its own two assessments where the subagent can, taking its read-only or delegated path only where it can't. Each returns its full report, with every finding's severity, location, and evidence. Both read the repo's `PRODUCT.md`; without one, they review without product context, and the hand back says so, pointing at `setup-ian-pascoe-skills`, which writes it with `impeccable`'s `init`. A desktop app has one window, so each subagent leaves it as it found it. Without a subagent tool, run each in turn yourself and say so in the hand back.

Done when both reports are back for every surface that takes this step, or a failed or skipped run is noted with the reason.

## 4. Triage

At the head, walk each interaction the change adds or alters and check each acceptance criterion the spec sets for the UI. Note each console error and failed request the head adds.

Classify every finding, the reports' and your own, against the base:

- **Introduced**: present at the head and absent at the base, so the change caused it. Every finding on a new surface is introduced.
- **Baseline**: present at the base too.

These UI findings block:

- each acceptance criterion the spec sets for the UI that the head fails;
- each introduced P0 or P1;
- each introduced render failure: a console error, a failed request, broken layout, overflow, or clipped text at a size the surface ships at.

The rest are advisory: introduced P2 and P3, and every baseline finding. A finding is **worth fixing** when its fix stays inside the change's spec and either it blocks, or it is advisory and you agree with it. A blocker whose fix would reach past the spec, such as a redesign or restyling a surface the change doesn't touch, isn't: it stays open with that reason, for the caller to fix or for the user to dismiss.

Done when every finding is classified as blocking or advisory, and marked worth fixing or not with the reason.

## 5. Fix

Fix each finding worth fixing, reading `impeccable`'s craft floor before the first edit and the playbook of the command its report suggests. Typecheck and run the tests covering the code you changed, then commit only the paths the fixes touch.

Done when each finding worth fixing is fixed in a commit, or its fix failed and it is left with the reason: open if it blocks, unfixed if it is advisory.

## 6. Capture screenshots and a demo

Capture from the head with the fixes, restarting it if it doesn't reload them. Evidence that shows a blocker still present leaves that blocker open.

**Screenshots.** For each rendered surface, screenshot the base and the head in the same state at each size it ships at: by default 1440×900 and 390×844 for a responsive web page, and the app's default window for a desktop app. Write them outside the repo, in a directory named for the branch under the system temp directory, as `<surface>-<size>-<base|head>.png`, so they stay out of the change's commits.

**Demo.** Record one short video of the change working at the head: its main flow, as the spec describes it, from the state a user starts in to the result they came for, at the surface's main size. Walk it once unrecorded to find the steps, then take it in one go, paced for a person watching: wait for each step to settle and hold on the result. Keep it under 30 seconds; a change with several independent flows gets one demo each. Save each beside the screenshots as `<flow>-demo.mp4`.

- `agent-browser`: `record start` with an `.mp4` path and `--cursor`, then `record stop`. It needs `ffmpeg`.
- `agent-desktop` has no recorder: record the window's bounds (`get --property bounds`) with `ffmpeg`'s screen grabber for the OS: `avfoundation` on macOS, which grabs the whole display, so crop it to the bounds at the display's scale (`list-displays`); `gdigrab` on Windows; `x11grab` on Linux under X11. Where screen recording is denied or unavailable, such as under Wayland, screenshot the window after each step and stitch the frames into an `.mp4` at one frame per second, and say the demo is a slideshow.

A demo that shows a failure, such as an error, a stuck state, or a step that does nothing, is an open blocker, not a demo; the rerun after its fix records the demo.

Done when every rendered surface has a base and a head screenshot at every size, and each flow has a demo that runs start to finish, or an open blocker in its place.

## 7. Hand back

Stop every app you started, remove the base worktree, and close your driver sessions, keeping the evidence directory. Then return:

- the evidence directory, with each surface's base and head screenshots by size, and each demo;
- each surface's audit and critique scores, or why it has none;
- each UI finding with its class, its severity, whether it blocks, and its outcome: fixed with the commit, or left with the reason, open if it blocks and unfixed if it is advisory;
- each unrendered surface and why;
- a **UI report** for the caller to post: the items above as a `## UI` section, with each surface's base and head screenshots side by side as Markdown images, and each demo, by their local paths.

The caller treats an open blocker as a blocking finding, and can rerun this skill on just the surfaces its later fixes touch. Run alone, show the user each surface's head beside its base and each demo, as media where the harness can display them, otherwise by path, and offer to post the UI report on the branch's open PR.

Done when every app you started is stopped and every item above is with the caller, or with the user run alone.

## Post the UI report

Whoever posts the UI report, on a PR or in a review report, puts its screenshots and demos on the code host first, finding the host with `code-host` (**Attach media**):

- **Upload** each file where the host reference has a working upload, swapping its local path for the hosted URL. Post a demo as video where the reference says the host plays it, otherwise as a GIF converted with `ffmpeg`; lower its frame rate and width until it fits the host's size cap.
- **Link** committed files where it has none, or the upload fails: commit the evidence to the repo's one `ui-evidence` branch on the push remote, in a temporary worktree, under `<branch>/<head>/`. Where the branch doesn't exist yet, start it with a commit that has no parent, so it shares no history with the code. Push without force; when another run pushed first, rebase onto its tip and push again, since each run writes only its own directory. Swap each local path for the reference's committed-file URL at the commit you pushed, committing a demo as a GIF. Leave the branch in place, since the links point into it.

Keep the evidence off the change's own branch, so it never enters the diff. Done when every screenshot and demo in the report resolves on the host.
