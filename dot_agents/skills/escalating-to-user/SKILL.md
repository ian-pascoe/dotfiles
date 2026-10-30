---
name: escalating-to-user
description: Decide on the user's behalf, escalating only the decisions that need them and reporting the rest in a ledger. Use when the user asks you to decide for them and only ask what you must, or when another skill names it.
---

Make the user's decisions for them and hand back only the few that truly need them, so they review one **ledger** instead of answering every question.

## Escalate sparingly

Decide everything yourself except a decision that passes **both** tests:

1. **User-held or split**: it turns on something only the user holds (a preference, priority, constraint, or fact you can't look up), or two answers are genuinely defensible. Facts you can look up, public ones included (library APIs, vendor limits, specs), are yours to find.
2. **Load-bearing**: the choice reshapes much of the work after it or is costly to reverse.

A decision that fails either test is yours: make the call and record it with a rationale and the strongest alternative you rejected.

## Keep moving

Escalating never blocks. Assume your recommended answer provisionally, mark everything resting on it, and carry on. Hold anything durable resting on a provisional answer (docs, commits, published changes) until the user confirms it.

## Present the ledger

```
## 🙋 Need you

❓ **E1** - **<question title>**: <question, with the options>

➡️ <your recommended answer; D<n> and what rests on it assume it>

## 👀 Worth a glance

- **D2.1** <the few calls (five at most) where you were least confident or that carry the most weight, one line each>

## 🌳 Decisions

- **D1** <decision>: <choice>. <why>, over <rejected alternative> because <reason>.
  - **D1.1** <decision>: <choice>. ...
```

Word each escalation so "yes" accepts your recommendation. Number decisions by path when they nest, so the user can override by ID ("D1.1: use X instead"). End each decision that produced an artifact with its target: `→ GLOSSARY: Order`, `→ ADR 0003`.

## Apply the reply

The user replies with answers and overrides. Redo the work resting on each changed decision, revising or deleting its artifacts, then present only the changed decisions and any new escalations. Act on the ledger once the user confirms it.
