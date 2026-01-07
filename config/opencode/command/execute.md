---
description: Execute a specific implementation plan. Provide a plan file as the argument to this command. It's very important this command runs in a new session.
---

# Execute Plan

Implement an approved plan from `thoughts/plans/`. Follow phases sequentially, verify each, update checkboxes as you go.

## TODO CREATION (MANDATORY)

**IMMEDIATELY after reading the plan**, create a todo list using `todowrite`:

1. One todo per plan phase (e.g., "Phase 1: Setup database schema")
2. Add verification todos after each phase (e.g., "Verify Phase 1: Run migrations")
3. Add final todos: "Update plan checkboxes", "Update beads status", "Run bd sync"

Mark each `in_progress` as you work, `completed` when done. **Never skip this step.**

## Core Workflow

1. **Read the plan completely** - Check for existing checkmarks (- [x]) to resume from
2. **Read the ticket and all files mentioned** - Full context, no limit/offset
3. **Verify beads status**: If plan references a beads ID, ensure it's `in_progress`: `bd update <id> --status=in_progress`
4. **Create todos from plan phases** - Break down into atomic implementation steps (see above)
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
- **Verify continuously** - Run `lsp_diagnostics` after each phase. Fix errors before proceeding.

## Verification Protocol

**After each phase:**

1. `lsp_diagnostics` on changed files - fix all errors before next phase
2. Run success criteria commands from plan
3. Mark phase checkbox only after verification passes

**For refactoring:**

- Use `lsp_find_references` before renaming/moving
- Use `lsp_rename` for safe cross-file renames
- Verify with `lsp_diagnostics` after each refactor step

## Failure Recovery

**After 2+ consecutive failed fix attempts:**

1. STOP further edits
2. REVERT to last working state (`git checkout` or undo)
3. Document what was attempted
4. Consult **oracle** with full failure context
5. If oracle cannot resolve → ask user before proceeding

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

- **explore**: Find files/patterns when unsure where something lives
- **librarian**: External library docs or OSS examples
- **oracle**: Deep architectural guidance when stuck (after 2+ failed attempts)
- **frontend-ui-ux-engineer**: Delegate visual/styling work in frontend files (colors, layout, animation)
- **multimodal-looker**: Analyze design mockups, diagrams, or screenshots referenced in plan

## Resuming Work

If checkmarks exist, trust completed work and pick up from first unchecked item.

**plan**

$ARGUMENTS
