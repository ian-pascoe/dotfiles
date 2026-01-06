---
description: Create an implementation plan from a ticket and research. Provide both the ticket and relevant research as arguments to this command. It is best to run this command in a new session.
---

# Create Implementation Plan

Create detailed implementation plans through interactive, iterative collaboration. Be skeptical, thorough, and verify everything against actual code.

## Process

### Step 1: Context Gathering

1. **Read all mentioned files FULLY** - Ticket, research, related plans
2. **Fire explore agents in parallel** to find relevant code, patterns, and structure
3. **Fire librarian agents in parallel** if external libraries are involved
4. **Wait for all agents, then read files they identified**

### Step 2: Present Understanding

```
Based on ticket and codebase research:

I found:
- [Implementation detail with file:line]
- [Relevant pattern discovered]

Questions I couldn't answer from code:
- [Technical question requiring judgment]
- [Business logic clarification]
```

Only ask questions you genuinely cannot answer through code investigation.

### Step 3: Research & Design

1. **If user corrects misunderstanding** - Verify with new research before proceeding
2. **Fire additional explore/librarian agents** for deeper investigation as needed
3. **Consult oracle** for complex architectural decisions or when multiple valid approaches exist
4. **Present design options** with pros/cons

**Agent selection:**
- `explore` - Find code patterns, trace implementations
- `librarian` - External docs, OSS examples, library best practices
- `oracle` - Architecture decisions, tradeoff analysis, validate approach before committing to plan

### Step 4: Plan Structure

Get buy-in on structure before writing details:

```
Proposed plan:
1. [Phase name] - [what it accomplishes]
2. [Phase name] - [what it accomplishes]

Does this phasing make sense?
```

### Step 5: Write Plan

Write to `thoughts/plans/{descriptive_name}.md`:

```markdown
# [Feature] Implementation Plan

## Overview
[Brief description]

## Current State Analysis
[What exists, constraints discovered]

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
- Research: `thoughts/research/...`
```

### Step 6: Review & Iterate

Present draft location, iterate on feedback, then update ticket status to `planned`.

## Guidelines

- **Be skeptical** - Verify with code, don't assume
- **Be interactive** - Get buy-in at each step, but don't over-ask
- **No open questions in final plan** - Resolve everything first
- **Separate automated vs manual verification** in success criteria
- **Proceed when clear** - If user's answer resolves ambiguity, continue without asking permission

**files**

$ARGUMENTS
