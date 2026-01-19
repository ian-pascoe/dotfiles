# Plan Versioning Protocol

How to safely update plan files when multiple agents may access them.

## Version Header Format

Every plan file should include a version header:

```markdown
# Plan: [Feature Name]

**Version**: 1.3
**Last Updated**: 2024-01-15T14:32:00Z
**Last Agent**: executor
**Status**: In Progress
```

## Version Incrementing

| Change Type        | Version Bump | Example    |
| ------------------ | ------------ | ---------- |
| Task status update | +0.1         | 1.0 → 1.1  |
| Add/remove task    | +0.1         | 1.1 → 1.2  |
| Phase completion   | +0.1         | 1.2 → 1.3  |
| Major restructure  | +1.0         | 1.3 → 2.0  |
| Initial creation   | 1.0          | (new file) |

## Read-Modify-Write Workflow

```
1. READ: Fetch current plan, note version number
2. MODIFY: Make your changes in memory
3. VERIFY: Check that your changes are coherent
4. WRITE: Save with incremented version and timestamp
```

**Critical**: Always update `Last Updated` and `Last Agent` fields.

## Field Protection

### Protected Fields (manual change only)

- `Status`: Draft → In Progress → Complete (only explicit request)
- `Complexity`: Set at creation, rarely changed
- `Overview`: Defines scope, change requires re-planning

### Auto-Mergeable Fields (safe to update)

- Task status checkboxes
- `Done when` criteria checkmarks
- `Last Updated` timestamp
- `Last Agent` identifier
- `Version` number

## Conflict Detection

Before writing, check if the plan changed since you read it:

```
1. If version hasn't changed: Proceed with write
2. If version changed: Re-read, merge your changes, write
3. If status changed (e.g., paused): Stop and escalate
```

## Merge Strategy

When version conflict detected:

1. Re-read the plan
2. Identify what changed (likely another task completed)
3. Apply your changes to the new state
4. Increment version from the new base
5. Write with merged content

## Session Handoff

When stopping mid-plan, leave a checkpoint:

```markdown
## Checkpoint

**Session**: [timestamp]
**Completed**: Tasks 1.1-1.4
**In Progress**: Task 2.1 (started, 50% done)
**Notes**: [Any context the next session needs]
**Blockers**: [If any]
```

## Example Plan Header

```markdown
# Plan: Add User Authentication

**Version**: 2.1
**Last Updated**: 2024-01-15T16:45:00Z
**Last Agent**: executor
**Status**: In Progress
**Complexity**: Medium
**Tasks**: 12

## Checkpoint

**Session**: 2024-01-15T16:45:00Z
**Completed**: Tasks 1.1-1.4, 2.1-2.2
**In Progress**: Task 2.3 (JWT validation)
**Notes**: Using jose library per architect recommendation
**Blockers**: None

## Overview

...
```
