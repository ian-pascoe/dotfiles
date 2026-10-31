---
name: addressing-pr-review
description: Fix or answer every unresolved finding on the current branch's PR, then push the fixes. Use when the current branch's PR has unresolved review threads, or the user asks to address its review.
---

Address every unresolved **finding** on the current branch's PR. A finding is an unresolved review thread, or a change a reviewer asked for outside any thread, such as in a blocking verdict or a review body's notes on lines outside the diff.

## Gather the findings

Find the code host with `code-host`, and stop if anything is missing, saying what; every host command below comes from its reference, under the heading in parentheses. Find the branch's open PR (**Find PRs**), and stop if it has none. Pull the PR's head into the current checkout if it is behind.

List the PR's unresolved review threads (**Review threads**), outdated ones included, then read its comments, review bodies, and blocking verdicts (**List comments**, **Blocking verdicts**) for changes asked for outside any thread. A blocking verdict counts while it stands. A comment or review body has no resolved state: it counts while it still applies to the current head and no reply has settled it.

Done when every unresolved thread and every outside-thread finding is on your list.

## Address each finding

Read the code each finding points at on the current head, then act by who raised it:

- **The user** (**Who am I**): act on it.
- **A bot**: fix it, or dismiss it with a reply giving the reason.
- **Another person**: fix it when you agree. When you don't, leave it open and raise it with the user.

Typecheck and run the tests covering the code you changed. Commit only the paths the fixes touch, report any other dirty files, and push to the branch's push remote.

Done when every finding is fixed in a pushed commit, dismissed with a reply, or held for the user.

## Close the threads

Once the push lands, resolve each thread you fixed or dismissed (**Review threads**); where the host can't resolve one, its reference says what clears a thread instead. Re-list the threads: each is resolved or held for the user. Findings that arrive after the push, such as a bot's re-review, belong to the next run.

## Report

List every finding with its outcome: fixed (with the commit), dismissed (with the reason), or held for the user (with your view), plus any dirty files left out.
