---
name: approaching
description: Take a change to a reviewed PR with passing checks, stopping short of the merge for a person's sign-off. Use when the user wants a change built and its PR opened, but not merged.
---

Bring the **change** the user approved onto **approach**: built, its PR open, its current diff passed review, its current head passed its checks, and nothing left between it and the merge but a person's **sign-off**. Run `landing` as written through **Start**, **Build**, **Review**, **Open the PR**, and **Pass checks**, keeping its friction log, cycles, and escalations; this skill replaces its **Merge** with a stop at sign-off.

## Stop at sign-off

Once the PR has passed **Pass checks**, re-read it and confirm the gates landing's **Merge** confirms just before merging, all but the approvals: missing approvals, and the block the host's readiness check shows for them, are the sign-off this skill stops for, so they don't hold the change. Anything else blocking, such as a conflict, holds it: escalate.

Leave the PR open with auto-merge off, and its tickets open for the merge to close. Done when every gate but approvals holds, or the change is held with its escalations.

## Retro and ledger

Run `closing-the-loop` as landing's **Retro** does, then present landing's ledger with the change on approach in place of landed: its PR link and the head that passed review and checks. Name every provisional answer the PR rests on, since the sign-off settles them. Tell the user how to land it once they sign off: merge it on the host, or run `landing` on the branch, which resumes at **Pass checks** and merges once its gates hold. A reviewer's threads in the meantime go to `addressing-pr-review`.
