---
name: grill-yourself-with-docs
description: Grill yourself down a plan's whole design tree, writing the glossary and ADRs as decisions settle.
disable-model-invocation: true
---

Run the `internal-grilling` and `domain-modeling` skills together. Every challenge `domain-modeling` would put to the user (a term clashing with the glossary, fuzzy language, a scenario probing a boundary, code contradicting the plan) becomes a node on your design tree. Write an ADR whenever `domain-modeling`'s three ADR tests pass, rather than offering one.
