---
name: split-grilling
description: Grill the user on a plan's architecture and yourself on its implementation detail, escalating only what needs the user. Use when the user wants to settle a plan's architecture together and leave the detail to you.
---

Split the `grilling` skill's design tree in two: the user owns the **architecture**, you own the **detail**. `grilling` and `internal-grilling` hold except where this skill overrides them.

## Draw the line

Sort every decision on the tree with the `codebase-design` skill's vocabulary:

- **Architecture** reaches past one module's implementation: where the modules and their seams go, each module's interface, the data model, external contracts and user-visible behaviour, domain terms, and the technologies and dependencies the plan takes on.
- **Detail** sits inside one module's implementation.

A decision that straddles the line is architecture.

## Grill the user on the architecture

Run `grilling` rounds with the user, asking only the architecture on the frontier. When an architecture question waits on a detail, decide that detail yourself, state it in the round, and carry it into the ledger as a decision; if it passes the `escalating-to-user` skill's escalation tests, ask it in the round instead.

The phase is done when every architecture question on the tree is answered.

## Grill yourself on the detail

Run `internal-grilling` over the rest of the tree, taking the user's answers as settled. Architecture that turns up here, such as a new seam, dependency, or contract, or a detail that would change one of the user's answers, is the user's whatever the escalation tests say: escalate it, with your recommendation as its provisional answer.

## Move decisions across the line

The user can move a decision across the line at any point:

- A question they hand back ("you decide") is yours: decide it and record it as a decision, which stays out of escalation.
- A decision they ask to weigh in on, a detail in a round or a `D` in the ledger, is theirs: ask it in the next `grilling` round, then redo the work resting on it.

Every answer the user gives, in a round or to an escalation, joins their answers. A revised answer reopens the subtree resting on it: ask its architecture in `grilling` rounds, redo its detail, and present only what changed. An answer of theirs the redo would change goes back to them.

## Present the ledger

Present `internal-grilling`'s ledger with a `## 🗣️ Settled with you` section just before its `## 🌳 Decisions`: the user's answers, numbered by path like the decisions (**A1**, **A1.1**), so they can revise one by ID.
