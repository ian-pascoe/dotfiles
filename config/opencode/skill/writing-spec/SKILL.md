---
name: writing-spec
description: Use when creating formal specifications with acceptance criteria. Covers spec structure, pre/post-conditions, invariants, interface definitions, and formal acceptance testing requirements.
---

# Writing Specifications

## Overview

Specifications are formal requirement documents that rigorously define WHAT a system must do before implementation begins. Unlike plans (which describe HOW to build), specs define contracts, interfaces, and acceptance criteria with precision sufficient for verification.

## When to Use

- Complex features requiring formal requirements documentation
- API contracts between systems or teams
- Features with strict acceptance criteria
- Work requiring sign-off before implementation
- Systems with invariants that must be preserved
- Multi-phase projects needing formal checkpoints

**Don't use for:** simple bug fixes, routine refactors, exploratory prototypes, or work where a plan suffices.

## File Location

```
.agents/specs/<name>.md          # Project-local specifications
```

Specs are stored in `.agents/specs/` (not `.opencode/`) because they are project artifacts, not agent configuration.

## Spec Structure Template

```markdown
# Specification: <Feature Name>

## Metadata

| Field      | Value                    |
| ---------- | ------------------------ |
| Version    | 1.0.0                    |
| Status     | Draft | Review | Approved |
| Author     | <name>                   |
| Created    | <ISO date>               |
| Updated    | <ISO date>               |
| Reviewers  | <names>                  |

## Overview

<2-3 sentences describing what this specification defines and why it exists>

### Context

<Background information, problem statement, or motivation>

### Scope

**In Scope:**
- <Item 1>
- <Item 2>

**Out of Scope:**
- <Item 1>
- <Item 2>

## Requirements

### Functional Requirements

| ID     | Requirement                     | Priority |
| ------ | ------------------------------- | -------- |
| FR-001 | <System shall...>               | Must     |
| FR-002 | <System shall...>               | Should   |

### Non-Functional Requirements

| ID      | Requirement                      | Metric           |
| ------- | -------------------------------- | ---------------- |
| NFR-001 | <Performance requirement>        | <measurable>     |
| NFR-002 | <Security requirement>           | <measurable>     |

## Interface Definitions

### API Contracts

```typescript
interface <Name> {
  // Input types
  // Output types
  // Error types
}
```

### Data Models

```typescript
type <EntityName> = {
  // Fields with types
};
```

### External Dependencies

| Dependency   | Interface         | Contract               |
| ------------ | ----------------- | ---------------------- |
| <System>     | <API/Protocol>    | <What we expect>       |

## Formal Conditions

### Pre-conditions

Conditions that MUST be true before operations execute:

- [ ] `PRE-001`: <Condition description>
- [ ] `PRE-002`: <Condition description>

### Post-conditions

Conditions that MUST be true after operations complete:

- [ ] `POST-001`: <Condition description>
- [ ] `POST-002`: <Condition description>

### Invariants

Conditions that MUST remain true throughout system operation:

- [ ] `INV-001`: <Condition description>
- [ ] `INV-002`: <Condition description>

## Acceptance Criteria

Each criterion must be testable and verifiable.

### AC-001: <Criterion Name>

**Given:** <Initial state/context>
**When:** <Action/trigger>
**Then:** <Expected outcome>

**Verification:** <How to test this>

### AC-002: <Criterion Name>

**Given:** <Initial state/context>
**When:** <Action/trigger>
**Then:** <Expected outcome>

**Verification:** <How to test this>

## Dependencies

### Blocking Dependencies

| Dependency         | Type     | Status  | Owner   |
| ------------------ | -------- | ------- | ------- |
| <What we need>     | Spec/API | Pending | <name>  |

### Downstream Dependents

- <What depends on this spec>

## Risks and Mitigations

| Risk                     | Likelihood | Impact | Mitigation               |
| ------------------------ | ---------- | ------ | ------------------------ |
| <Risk description>       | High/Med/Low | High/Med/Low | <Mitigation strategy> |

## Appendix

### Glossary

| Term   | Definition              |
| ------ | ----------------------- |
| <Term> | <Definition>            |

### References

- <Link to related docs>

```

## Common Mistakes

| Mistake                          | Fix                                              |
| -------------------------------- | ------------------------------------------------ |
| Requirements not testable        | Each requirement must have measurable criteria   |
| Missing pre/post-conditions      | Always define what must be true before/after     |
| Vague acceptance criteria        | Use Given/When/Then format with verification     |
| Mixing HOW with WHAT             | Specs define contracts, not implementation       |
| No version tracking              | Always include version and status in metadata    |
| Scope creep                      | Explicitly list what is OUT of scope             |

## Validation Checklist

- [ ] Metadata complete (version, status, author, dates)
- [ ] Overview clearly states purpose and context
- [ ] Scope explicitly defines in/out of scope items
- [ ] All requirements have IDs and priorities
- [ ] Non-functional requirements have measurable metrics
- [ ] Interface definitions are complete and typed
- [ ] Pre-conditions, post-conditions, and invariants defined
- [ ] Acceptance criteria use Given/When/Then format
- [ ] Each acceptance criterion has a verification method
- [ ] Dependencies identified with owners and status
- [ ] Risks assessed with mitigations
- [ ] No implementation details (HOW) in the spec
