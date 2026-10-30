---
name: landing
description: Land a change by building it, passing code-review, opening its PR, and merging it once its checks pass. Use when the user asks for a change to be landed or merged, not just implemented.
---

Land the **change** the user approved: a ticket they name, or the plan just settled in the conversation. It is landed when its PR is merged into the default branch and its tickets are closed. Run the `code-host`, `tdd`, `code-review`, and `pr` skills where named, and decide along the way under `escalating-to-user`; each holds except where this skill overrides it. Each round of fixes, for review or checks, is one cycle; after three cycles, hold the change and escalate.

## Start

If the user names a ticket, fetch it from the issue tracker and state its title. Otherwise the spec is the plan settled in the conversation, or the PR's `## Plan` on a resumed PR: land it without filing a ticket.

Find the **code host** with `code-host`; every host command below comes from its **code host reference**, under the heading in parentheses, like (**Checks**). Escalate an ambiguous host; on anything else missing, stop and say what. Push branches to the repo itself, never to a fork. Note in the ledger when the rules wouldn't bind you (**Bypass check**).

Work in the current checkout. If HEAD is detached or on the default branch, branch from the up-to-date default branch (**Default branch**) as `<ticket>-<slug>`, or `<slug>` without a ticket; otherwise keep the current branch. If the branch already has an open PR (**Find PRs**), go to **Pass checks** if the latest review report on the PR (**List comments**, or its body's `## Review`) covers its current diff (it names the current head, or `git range-diff` shows only `=` against the head it names), otherwise to **Review**.

## Build

Build with `tdd`. Seams named in the plan or ticket count as agreed; otherwise choose them yourself and list them in the PR body.

Typecheck and run single test files as you go, and the full suite once at the end. Commit only the paths the change touches, and report any other dirty files.

## Review

Review every diff before the push that carries it, so checks run only on reviewed code; every later fix comes back through this section. The PR's **target** is the default branch, or the branch a stacked change stacks on. Fetch, then run `code-review` with `origin/<target>` as the fixed point, writing `git diff origin/<target>...HEAD` to a file named for the branch and giving its path to the reviewers, so they review the diff even without a shell. Blocking findings are every Spec finding and every hard violation of a documented standard; baseline smells are advisory, so fix the ones you agree with and list the rest in the PR. Clear each blocker by fixing it, or by dismissing it with a reason recorded as a decision, escalating a dismissal only the user can judge. Review again after fixes, until no blockers remain.

Post each passing report as a **review report**: a top-level comment the host doesn't count as an open thread (**Comment**), or where the host has none, a `## Review` section of the PR body (**Edit PR body**), naming the head commit it reviewed, with its dismissals and their reasons, so a later run can tell which diff was reviewed; the first waits for **Open the PR**.

## Open the PR

Push the head the review report names to the branch's push remote: `git push <remote> <reviewed-sha>:refs/heads/<branch>`, with `--force-with-lease` after a rebase, so only reviewed commits go up. If the branch has no PR yet, open one against its target (**Open PR**), writing its body with `pr`. When the tracker is the code host, add its closing keyword for each ticket (**Closing tickets**); without a ticket, add the settled plan under `## Plan`. Then post the review report.

## Pass checks

The PR is ready to merge once its current diff has passed review and its current head has passed its checks.

**Checks.** Wait on the PR's checks (**Checks**), polling every 30 s where the host has no watch command. When no check has changed state for 60 minutes, escalate and keep waiting. The PR has no checks only when the merge rules require none, the repo has no workflow config for the host, and nothing has reported 2 minutes after the push; say so in the ledger. On a failure, read the logs: rerun once if it looks flaky, otherwise fix it and take the fix through **Review** and **Open the PR**. A fresh run counts as the rerun only if it reports to the PR's check; where the host can't start one, the failure is real. If the same check is red on the default branch's head too, it isn't this change's to fix: escalate.

**Review threads.** Treat every unresolved review thread and every reviewer's blocking verdict, such as changes requested (**Review threads**, **Blocking verdicts**), as a finding: act on the user's, fix a bot's or dismiss it with a reply, and fix another person's when you agree, taking each fix through **Review** and **Open the PR**. Resolve a thread once it is fixed or a bot's is answered; where the host can't, its reference says what clears a thread instead, and the ledger lists the threads left open. Leave a person's thread you disagree with open, and escalate.

**Freshness.** If the default branch has moved since the checks ran, rebase onto it, push with `--force-with-lease`, and wait for the checks again; a rebase is not a fix cycle. A rebase that leaves the diff unchanged (`git range-diff` shows only `=`) keeps the review; one with hand-resolved conflicts goes through **Review** first.

## Merge

Hold a PR whose merge rests on a provisional answer until the user confirms that answer. Merge only this run's PRs: those it opened or resumed.

The code host's **merge rules** gate every merge: merge through them as they stand, and leave enabling auto-merge, bypassing, and changing the rules to the user. Landing's own gates hold on every host, even where the rules wouldn't bind you. Just before merging, re-read the PR and confirm:

- a review report names its current head;
- every check on that head is green;
- no review thread is unresolved and no blocking verdict stands;
- it has the approvals the rules require, and the host's readiness check shows nothing blocking but pending checks (**Approvals & readiness**).

Wait while checks are pending; if anything else blocks, hold the PR and escalate.

Merge (**Merge**), passing the method explicitly: squash, else a merge commit, else rebase, as the repo allows (**Merge methods & merge queue**). Pin the merge to the reviewed head; where the host can't, re-read the head first and go back to **Review** if it moved. Where the rules require a **merge queue**, this merge enters it: that is the host's gate, entered once landing's own gates pass.

Then read the PR back (**Read back**):

- **Merged**: confirm the merged head is the reviewed one, escalating if not. Delete the branch if the merge didn't (**Delete branch**). Check each ticket is closed, and close any still open through the tracker doc.
- **In a required merge queue**: wait as for checks. Ejected for another PR's failure, re-enqueue once, which counts as the rerun; ejected for its own, handle it as a failed check.
- **Anything else**, such as auto-merge switched on or a merge still pending: cancel any auto-merge, hold the PR, and escalate.

## Present the ledger

Present the ledger after acting rather than before: the change landed, or held with its escalations and any open PR, every decision including dismissed findings, and any dirty files left out.
