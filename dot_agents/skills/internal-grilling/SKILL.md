---
name: internal-grilling
description: Grill a plan internally, answering your own questions down its whole design tree and escalating only what needs the user. Use when the user wants a plan stress-tested without being interviewed.
---

Run the `grilling` skill as an internal dialogue: answer your own questions, and put to the user only what the `escalating-to-user` skill escalates. Both skills hold except where this skill overrides them.

## Answer your own questions

Where `grilling` puts a decision to the user, decide it yourself. Play devil's advocate: name the strongest alternative answers, argue against your favourite, then decide. Each decision pushes the frontier outward; recompute it and keep walking without pausing between rounds.

When a load-bearing decision rests on a public fact, find the fact with the `research` skill and make its findings file the decision's artifact.

## Present the ledger

When the frontier is empty, every node is decided or escalated. Present the ledger with the design tree as its decisions.
