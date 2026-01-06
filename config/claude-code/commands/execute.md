---
description: Execute a specific implementation plan. Provide a plan file as the argument to this command. It's very important this command runs in a new session.
---

# Execute Plan

Implement an approved plan from `thoughts/plans/`. Follow phases sequentially, verify each, update checkboxes as you go.

## Core Workflow

1. **Read the plan completely** - Check for existing checkmarks (- [x]) to resume from
2. **Read the ticket and all files mentioned** - Full context, no limit/offset
3. **Verify beads status**: If plan references a beads ID, ensure it's `in_progress`: `bd update <id> --status=in_progress`
4. **Create todos from plan phases** - Break down into atomic implementation steps
5. **Implement each phase** - Adapt to reality while following plan intent
6. **Verify each phase** - Run success criteria checks, fix issues before proceeding
7. **Update the plan** - Mark completed items with checkboxes
8. **Update statuses**:
   - Set ticket frontmatter to `status: implemented`
   - If issues were discovered, create new beads issues: `bd create --title="..." --type=bug`
   - Link discovered issues: `bd dep add <new-id> <original-id> --type=discovered-from`

## Execution Principles

- **Bias toward action** - Plan is clear → implement. Don't re-research documented decisions.
- **Adapt, don't abandon** - Reality differs slightly → adapt. Only pause for major blockers.
- **Use session context** - Don't re-read files you just wrote.
- **Ask only when blocked** - Make reasonable decisions and document why.
- **Track discovered work** - Create beads issues for bugs/improvements found during execution.
- **Verify continuously** - Run type checker after each phase. Fix errors before proceeding.

## Verification Protocol

**After each phase:**
1. Run project type checker (e.g., `tsc --noEmit`, `mypy`, `cargo check`) - fix all errors before next phase
2. Run success criteria commands from plan
3. Mark phase checkbox only after verification passes

**For refactoring:**
- Use Grep to find all references before renaming/moving
- Make renames carefully across all files found
- Re-run type checker after each refactor step

## Failure Recovery

**After 2+ consecutive failed fix attempts:**
1. STOP further edits
2. REVERT to last working state (`git checkout` or undo)
3. Document what was attempted
4. Use **general-purpose** agent for deep research, or **AskUserQuestion** for guidance
5. If still blocked → ask user before proceeding

**Never:** Leave code broken, shotgun debug, delete failing tests to "pass"

## When Things Don't Match

If the plan doesn't match reality:

```
Issue in Phase [N]:
Expected: [what plan says]
Found: [actual situation]
```

Document deviations in the plan under `## Deviations from Plan` with: original plan, actual implementation, reason, and impact.

## Agent Usage

- **Explore**: Find files/patterns when unsure where something lives (Task tool with subagent_type=Explore)
- **general-purpose**: Complex multi-step research tasks (Task tool with subagent_type=general-purpose)
- **WebSearch/WebFetch**: External library docs or examples
- **Read**: View design mockups, diagrams, or screenshots (supports images and PDFs)

## Resuming Work

If checkmarks exist, trust completed work and pick up from first unchecked item.

**plan**

$ARGUMENTS
