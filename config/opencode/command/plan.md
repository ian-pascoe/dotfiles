---
description: Research a ticket and create an implementation plan. Provide a ticket file or beads ID as the argument. It is best to run this command in a new session.
---

# Research & Plan

Research the codebase and create a detailed implementation plan from a ticket. This combines investigation and planning into a single workflow.

## TODO CREATION (MANDATORY)

**IMMEDIATELY** create a todo list before any other action:

```
1. Read and claim ticket
2. Research codebase (parallel agents)
3. Present understanding to user
4. Design approach
5. Get buy-in on plan structure
6. Write plan document
7. Review and finalize
```

Use `todowrite` to create these items, then mark each `in_progress` as you work and `completed` when done.

## Process

### Step 1: Read & Claim

1. **Read the ticket FULLY** (from `thoughts/tickets/` or via `bd show <id>`)
2. **Claim the work**: `bd update <id> --status=in_progress`
3. **Break down into research areas** - What do I need to find to plan this?
4. **Identify external dependencies** - Any unfamiliar libraries or patterns?

### Step 2: Research (parallel agents)

**Phase 1 - Locate & Discover:**

- Fire **explore** agents in parallel to find relevant code, patterns, structure
- Fire **librarian** agents if external libraries are involved
- Use **multimodal-looker** if ticket references diagrams, screenshots, or PDFs
- Wait for all to complete

**Phase 2 - Deep Analysis (if needed):**

- Fire additional agents for areas needing deeper investigation
- Consult **oracle** for architectural complexity or tradeoff analysis
- **Stop when you have enough** - 2 iterations with no new info = done

**Read all files identified by agents.**

### Step 3: Present Understanding

```
Based on ticket and codebase research:

I found:
- [Implementation detail with file:line]
- [Relevant pattern discovered]
- [Constraint or complexity identified]

Questions I couldn't answer from code:
- [Technical question requiring judgment]
- [Business logic clarification]
```

Only ask questions you genuinely cannot answer through code investigation.

### Step 4: Design

1. **If user corrects misunderstanding** - Verify with new research before proceeding
2. **Consult oracle** for complex architectural decisions or when multiple valid approaches exist
3. **Present design options** with pros/cons if multiple valid approaches exist

### Step 5: Plan Structure

Get buy-in on structure before writing details:

```
Proposed plan:
1. [Phase name] - [what it accomplishes]
2. [Phase name] - [what it accomplishes]

Does this phasing make sense?
```

### Step 6: Write Plan

Write to `thoughts/plans/{descriptive_name}.md`:

```markdown
# [Feature] Implementation Plan

## Overview
[Brief description]

## Beads Reference
- Issue: `<beads-id>`

## Research Findings
[Key discoveries from codebase investigation]
- [Finding with file:line reference]
- [Pattern to follow]
- [Constraint discovered]

## Current State
[What exists now]

## Desired End State
[Specification and verification method]

## What We're NOT Doing
[Explicit out-of-scope items]

## Phase 1: [Name]

### Changes Required
**File**: `path/to/file.ext`
**Changes**: [Summary]

### Success Criteria
#### Automated:
- [ ] `command` - description

#### Manual:
- [ ] [Verification step]

## Phase 2: [Name]
[Same structure...]

## Testing Strategy
[Unit, integration, manual steps]

## References
- Ticket: `thoughts/tickets/...`
```

### Step 7: Review & Finalize

Present draft location, iterate on feedback, then:

1. Update ticket file frontmatter to `status: planned`
2. Run `bd sync` to sync any changes

## Agent Selection

| Agent | When to Use |
|-------|-------------|
| `explore` | Find code patterns, trace implementations, locate files |
| `librarian` | External docs, OSS examples, library best practices |
| `oracle` | Architecture decisions, tradeoff analysis, validate complex approaches |
| `multimodal-looker` | Analyze diagrams, mockups, screenshots, PDFs |

## Guidelines

- **Be skeptical** - Verify with code, don't assume
- **Be interactive** - Get buy-in at each step, but don't over-ask
- **No open questions in final plan** - Resolve everything first
- **Separate automated vs manual verification** in success criteria
- **Proceed when clear** - If user's answer resolves ambiguity, continue without asking permission
- **Don't over-research** - Stop when you have enough context

## Complexity Signals

**Split into multiple plans when:**

- Changes span 3+ unrelated subsystems
- Requires sequential PRs (migrations, breaking changes)
- Total estimated phases > 6

**Keep as single plan when:**

- All changes serve one cohesive goal
- Can be reviewed/tested as one unit

**ticket**

$ARGUMENTS
