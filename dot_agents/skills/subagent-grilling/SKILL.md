---
name: subagent-grilling
description: Grill a strong-model subagent down a plan's whole design tree in the user's place, escalating only what needs the user. Use when the user wants a stronger model to answer a plan's design questions.
---

Run the `grilling` skill with a subagent, the **interviewee**, in the user's seat: you ask, it answers. A strong model makes the calls, you keep the interview relentless, and the user hears only what the `escalating-to-user` skill escalates. Both skills hold except where this skill overrides them.

## Confirm the interviewee's model

Before spawning, confirm the interviewee's model with the user, unless they already named one or the harness offers no choice. List the available models or configured roles, recommend the strongest at design reasoning with high effort, and word the question so "yes" accepts. Spawn nothing until they answer.

## Brief the interviewee

Spawn a persistent subagent you can send round after round. It shares none of your context, so the brief carries:

- The goal and the plan as it stands, with the decisions and constraints the user has already settled.
- Paths to the files, docs, and code it bears on.
- Its role: answering a design interview on the user's behalf under the `escalating-to-user` skill. Answer every question in a round, numbered to match, with a decision, a one-line why, and the strongest alternative rejected. Flag an answer that passes the escalation tests as **ESCALATE**, keeping its recommendation. Flag an answer whose load-bearing decision rests on a public fact as **RESEARCH**, naming the fact it assumed and leaving the lookup to the asker.

## Run the rounds

Send each round to the interviewee in place of the user. Challenge an answer that is thin or clashes with what the user has said; the challenge joins the next round.

Settle each **RESEARCH** flag, and any public fact you spot a load-bearing decision resting on, with the `research` skill, and put its findings to the interviewee in the next round; the findings file is the decision's artifact.

The escalation call is yours, since you hold the user's context: run each answer through `escalating-to-user`'s tests, whether flagged or not. An escalated answer becomes your provisional recommendation; tell the interviewee it is provisional.

## Present the ledger

When the frontier is empty, every node is decided or escalated. Present the ledger with the design tree as its decisions. Send the user's answers and overrides to the interviewee as settled, and reopen the subtrees they change in new rounds.
