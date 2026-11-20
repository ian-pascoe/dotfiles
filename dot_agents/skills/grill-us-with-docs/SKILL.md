---
name: grill-us-with-docs
description: Grill you on a plan's architecture and itself on the implementation detail, writing the glossary and ADRs as decisions settle.
disable-model-invocation: true
---

Run the `split-grilling` and `domain-modeling` skills together. Every challenge `domain-modeling` would put to the user (a term clashing with the glossary, fuzzy language, a scenario probing a boundary, code contradicting the plan) becomes a node on the design tree, sorted like any other. Write an ADR whenever `domain-modeling`'s three ADR tests pass, rather than offering one.
