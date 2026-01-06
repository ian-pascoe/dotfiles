---
description: Execute a specific implementation plan. Provide a plan file as the argument to this command. It's very important this command runs in a new session.
---

# Execute Plan

Implement an approved plan from `thoughts/plans/`. Follow phases sequentially, verify each, update checkboxes as you go.

## Core Workflow

1. **Read the plan completely** - Check for existing checkmarks (- [x]) to resume from
2. **Read the ticket and all files mentioned** - Full context, no limit/offset
3. **Create todos from plan phases** - Break down into atomic implementation steps
4. **Implement each phase** - Adapt to reality while following plan intent
5. **Verify each phase** - Run success criteria checks, fix issues before proceeding
6. **Update the plan** - Mark completed items with checkboxes
7. **Update ticket status** - Set frontmatter to `status: implemented`

## Execution Principles

- **Bias toward action** - If the plan is clear, implement. Don't re-research what's already documented.
- **Adapt, don't abandon** - If reality differs slightly from plan, adapt. Only pause for major blockers.
- **Use session context** - You know what you just did. Don't re-read files you just wrote.
- **Ask only when blocked** - If you can make a reasonable decision, make it and document why.

## When Things Don't Match

If the plan doesn't match reality:

```
Issue in Phase [N]:
Expected: [what plan says]
Found: [actual situation]
```

Document deviations in the plan under `## Deviations from Plan` with: original plan, actual implementation, reason, and impact.

## Agent Usage

- **explore**: Find files/patterns when unsure where something lives
- **librarian**: External library docs or OSS examples
- **oracle**: Deep architectural guidance when stuck (after 2+ failed attempts)
- **frontend-ui-ux-engineer**: Delegate visual/styling work in frontend files (colors, layout, animation)
- **multimodal-looker**: Analyze design mockups, diagrams, or screenshots referenced in plan

## Resuming Work

If checkmarks exist, trust completed work and pick up from first unchecked item.

**plan**

$ARGUMENTS
