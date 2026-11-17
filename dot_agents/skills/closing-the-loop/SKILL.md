---
name: closing-the-loop
description: Close the loop on a coding run by looking back at its friction, deciding which environment fixes are worth making, and making or filing them. Use when another skill names it, or the user wants a retro that acts on its findings.
metadata:
  credits:
    skill: retro
    author: Matt Pocock
    url: "https://github.com/mattpocock/skills/blob/main/skills/engineering/retro/SKILL.md"
---

Close the loop on a coding run: look back at what in the agent's **environment**, not its code, made the run harder, decide which fixes are worth making, and route each one to where it gets done, so the next run starts from a better environment. Decide under `escalating-to-user`.

## Friction log

The **friction log** records each moment a run fought its environment rather than the work: a file or fact that took a long search, a mistake a check or the reviewer should have caught, a tool call that cost more than it returned, a red check, a fix cycle, a flaky rerun, an escalation, or information the agent couldn't reach. Each entry names its moment, such as the commit, check, finding, or tool call, and what it cost.

A skill that runs this one keeps the log from the start of its run and passes it in, with the **current scope**: open work it can still take fixes into, or none. Run on your own, build the log from the current session's record, or the session the user names, and take that session's open work as the current scope.

## Steps

1. Take the friction log. If it is empty, report that the run was smooth and stop.

2. Run `writing-for-agents` for the reference behind steering files and skills.

3. **Diagnose.** For each entry, find the cause in the environment and the change that would have prevented it, in one of the **categories** below, placed as **Where changes go** says. Done when every entry has a candidate fix or a reason it has none.

4. **Triage.** Hold each candidate to **the bar**. Record each one that misses as a decision naming the test it failed. Done when every candidate is kept or dropped.

5. **Route** each kept fix, and act on its route. Done when every kept fix is made or handed back, filed, escalated, or drafted.

6. Report in order of severity: each fix with its log entry, category, change, and route, with the link of what you filed; then the dropped candidates and why.

## Categories

- **Navigation**: the agent took long to find a file or fact. Add a **navigation pointer** from a file it already reads, or expose a hidden dependency between files.
- **Automated checks**: the agent made a mistake a lint rule, type, test, or filesystem check could catch. Read the repo's own check command and CI first, so a check that exists but sits unwired or broken is the cause. When the repo has no **guardrail** at all (no pre-commit hook and no CI job running its lint, typecheck, and tests), the missing guardrail is the cause, and the fix is the guardrail.
- **Coding standards**: the reviewer missed a mistake. Classify it first: a **mechanical** violation (a fixed syntactic pattern, a banned API, an import shape, a file-location rule) gets a deterministic check in the repo's linter, a pre-commit hook, or a CI job, whichever is cheapest. Reserve `CODING_STANDARDS.md` for **judgement calls** no check could make.
- **Steering files**: the agent missed, misread, or was misled by a line in `AGENTS.md` or `CLAUDE.md`, in the repo or the user's global scope. When the file is large, the fix moves its steering into standards or checks, and deletes **no-ops**: lines that don't change the agent's behaviour.
- **Tool economy**: a tool call was expensive for what it returned. Streamline or replace the tool.
- **Information access**: the agent needed information it couldn't reach. Widen its access, such as teeing a dev server's log to a file or read-only access to a service.

## Where changes go

Standards belong to the **reviewer**, not the implementer. The implementer carries the most context pressure: it explores, writes code, and debugs. The reviewer gets a diff, so it has room to apply rules.

- `AGENTS.md` / `CLAUDE.md`: loaded into every session, so they hold navigation pointers and little else.
- `CODING_STANDARDS.md`: read during review. Create it with the first judgement-call rule. Past 1,000 lines, point from it into a docs folder.
- Docs: reference files reached by pointers. Extend an existing doc before writing a new one.
- Skills: for reference whose description should reach the agent, or for commands the user types.

## The bar

A fix is worth making only when it passes all four tests:

1. **Traced**: it answers a logged moment with a real cost, such as tool calls, a fix cycle, a red check, an escalation, or a held change.
2. **Environmental**: the cause is a missing or broken check, pointer, standard, tool, or access, not the work's own difficulty, a one-off slip, or a transient outage.
3. **Recurring**: the next run on this kind of work would likely hit it again. An open ticket or issue already filed for the same cause is proof.
4. **Cheaper**: the fix costs less than the friction it prevents, counting its standing costs: lines in always-loaded files, false positives from a check, and upkeep.

When a test is in doubt, drop the candidate. Dropping costs little: friction that recurs reaches a later run's log and passes then.

## Routes

The route follows where the fix lives and whether the current scope already covers it:

- **Current scope**: there is a current scope, and its spec already covers the fix. Hand it back to the skill that ran this one, to make as part of that work; run on your own, make it yourself.
- **Follow-up ticket**: the fix lives in this repo, or another project repo the user owns, outside the current scope. File it as that repo's `docs/agents/issue-tracker.md` says, or on its code host's issues where it has none, with the `needs-triage` role's label from its `docs/agents/triage-labels.md` where it has one. If an open ticket covers the same cause, comment the new moment on it instead.
- **Outside issue**: the fix lives in a repo the user doesn't own, such as a skill installed from elsewhere, a CLI, a library, or an MCP server. Draft the issue, and ready it for filing only when all of these hold; otherwise it stays a draft in the report:
  - the cause is in that repo's code or docs, not in how this repo uses it;
  - you can give steps that reproduce it, which a maintainer can follow without this repo;
  - no open issue covers it, after a search; when one does, report its link instead;
  - the repo accepts issues, and the draft follows its contributing guide and templates.

  Write it for the maintainer: what happened, how to reproduce it, and what you expected. The tracker doc holds filing to the user's own repos, so filing elsewhere takes the user's yes, overriding the tracker doc for that issue: escalate each ready draft, worded so "yes" files it, and file it on that yes. A draft for a repo the tracker doc names as never to file into stays in the report, for the user to file.

- **Proposal**: the fix lives in the user's own setup, such as their global `AGENTS.md`, dotfiles, or harness config, even where a repo holds it. Draft the change in the report for the user to pick.

Anything filed, or drafted for filing, outside the repo the run worked in leaves out that repo's private names, paths, and secrets.
