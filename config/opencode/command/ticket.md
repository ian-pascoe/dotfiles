---
description: Creates a structured ticket as a beads issue for bugs, features, or technical debt based on user input.
---

# Create Ticket

Create comprehensive beads issues that serve as the foundation for the `/plan` command.

## Process

### Step 1: Initial Analysis

1. **Determine ticket type**:
   - **bug**: Something broken, errors, unexpected behavior
   - **feature**: New functionality or enhancement
   - **task**: Refactoring, code cleanup, architecture improvements, general work

2. **Extract initial keywords** - Component names, file patterns, error messages, technologies

### Step 2: Interactive Questions

Ask targeted questions based on ticket type:

**Bug**: What behavior? What should happen? Steps to reproduce? When did it start? Error messages?

**Feature**: What problem does it solve? Who are users? Acceptance criteria? UI/UX requirements? Integration needs?

**Task**: What code needs improvement? What problems does it cause? Ideal state after cleanup?

### Step 3: Scope Exploration

Attempt to expand scope until user pushes back with "out of scope". Generate follow-up questions to find actual boundaries.

**Signs of complete scope**: User says "out of scope", or scope is clearly atomic and well-defined.

**Adjust intensity based on complexity**: Simple bugs need less exploration than large features.

### Step 4: Create Beads Issue

Use `bd create` to create the issue:

```bash
bd create --title="[Descriptive Title]" --type=[bug|feature|task] --priority=[0-4]
```

Priority: 0=critical, 1=high, 2=medium, 3=low, 4=backlog

Then create a detailed ticket file at `thoughts/tickets/{type}_{subject}.md` and reference the beads ID:

```markdown
---
beads_id: [beads-xxx]
type: [bug|feature|task]
priority: [0-4]
created: [ISO date]
status: open
keywords: [search terms for research]
patterns: [code patterns to investigate]
---

# [Title]

## Description
[Clear description]

## Context
[Background, business impact]

## Requirements

### Functional
- [Requirement]

### Non-Functional
- [Performance, security constraints]

## Current State
[What exists now]

## Desired State
[What should exist after]

## Research Context

### Keywords to Search
- [keyword] - [why relevant]

### Patterns to Investigate
- [pattern] - [what to look for]

### Key Decisions Made
- [decision] - [rationale]

## Success Criteria

### Automated
- [ ] [Test command]

### Manual
- [ ] [Verification step]
```

### Step 5: Validate & Confirm

Review completeness, validate logic, check scope is atomic and well-scoped.

For complex tickets, consider consulting **oracle** to validate:
- Requirements are complete and unambiguous
- Success criteria are measurable
- Scope is appropriately sized

### Step 6: Sync

Run `bd sync` to ensure the issue is tracked.

## Guidelines

- **Atomic tickets** - One concern per ticket
- **Research-friendly** - Include specific keywords and patterns
- **Testable** - Clear success criteria
- If scope seems too broad, suggest breaking into multiple tickets with `bd dep add` to link them

**user_request**

$ARGUMENTS
