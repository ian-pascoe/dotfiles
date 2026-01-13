---
name: writing-plans
description: Use when creating, editing, or reviewing implementation plans. Covers plan structure, version headers, task phases, acceptance criteria, and checkpoint format.
---

# Writing Plans

## Overview

Plans are step-by-step implementation guides that enable executor agents to complete work autonomously. A plan breaks complex features into ordered, atomic tasks with clear acceptance criteria.

## When to Use

- Creating a new implementation plan
- Editing or updating an existing plan
- Reviewing plan quality before execution
- Adding checkpoints for session handoffs
- Understanding plan versioning rules

**Don't use for:** one-off tasks (use TodoWrite), project documentation (use AGENTS.md), or design decisions (use architect agent).

## File Location

```
.agents/plans/<name>.md     # Project-local plans
```

Plan names should be kebab-case, matching the feature: `user-avatar-upload.md`, `auth-refresh-tokens.md`.

## Version Header Format

Every plan MUST include a version header:

```markdown
# Plan: [Feature Name]

**Version**: 1.0
**Last Updated**: 2024-01-15T10:00:00Z
**Last Agent**: planner
**Status**: Draft
**Complexity**: Low | Medium | High
**Tasks**: [N]
```

### Version Incrementing

| Change Type        | Version Bump | Example    |
| ------------------ | ------------ | ---------- |
| Initial creation   | 1.0          | (new file) |
| Task status update | +0.1         | 1.0 → 1.1  |
| Add/remove task    | +0.1         | 1.1 → 1.2  |
| Phase completion   | +0.1         | 1.2 → 1.3  |
| Major restructure  | +1.0         | 1.3 → 2.0  |

### Status Values

- **Draft**: Plan created, not yet started
- **In Progress**: Execution underway
- **Paused**: Stopped due to blocker
- **Complete**: All tasks finished

## Plan Structure Template

```markdown
# Plan: [Feature Name]

**Version**: 1.0
**Last Updated**: [ISO timestamp]
**Last Agent**: planner
**Status**: Draft
**Complexity**: Low | Medium | High
**Tasks**: [N]

## Overview

[1-2 sentences describing the goal and scope]

## Tasks

### Phase 1: [Phase Name]

#### 1.1 [Task Name]

**File**: `path/to/file.ts`

[What to do - describe the change, not how to implement]

**Done when**:

- [ ] [Criterion 1]
- [ ] [Criterion 2]

#### 1.2 [Task Name]

**File**: `path/to/file.ts`

[Continue pattern...]

**Done when**:

- [ ] [Criterion 1]

### Phase 2: [Phase Name]

#### 2.1 [Task Name]

[Continue pattern...]

## Testing

- [ ] [Test category]: [What to verify]
- [ ] [Test category]: [What to verify]

## Risks

| Risk       | Mitigation          |
| ---------- | ------------------- |
| [Risk 1]   | [How to handle]     |
| [Risk 2]   | [How to handle]     |
```

## Task Format

Each task must include:

1. **Numbered ID**: `X.Y` format (phase.task)
2. **File**: Target file path (required for code tasks)
3. **Description**: What to do (not how)
4. **Done when**: Checklist of acceptance criteria

### Good Task Example

```markdown
#### 2.1 Add Avatar Upload Route

**File**: `src/routes/users.ts`

Create POST /users/:id/avatar endpoint that accepts multipart form data.

**Done when**:

- [ ] Route accepts multipart/form-data
- [ ] Validates user owns profile or is admin
- [ ] Returns new avatar URL on success
- [ ] Returns 400 on invalid file type
```

### Bad Task Example

```markdown
#### 2.1 Implement avatar stuff

Add the avatar upload feature to the backend.
```

Problems: No file path, vague description, no acceptance criteria.

## Checkpoint Format

When stopping mid-plan, add a checkpoint section:

```markdown
## Checkpoint

**Session**: 2024-01-15T16:45:00Z
**Completed**: Tasks 1.1-1.4, 2.1-2.2
**In Progress**: Task 2.3 (started, ~50% done)
**Notes**: Using jose library per architect recommendation
**Blockers**: Waiting for API key from external team
```

Place checkpoint after the version header, before Overview.

## Common Mistakes

| Mistake                       | Fix                                          |
| ----------------------------- | -------------------------------------------- |
| No file paths on tasks        | Always include `**File**: path/to/file.ts`   |
| Mega-tasks (multi-session)    | Split into atomic, single-session tasks      |
| Missing acceptance criteria   | Every task needs `**Done when**` checklist   |
| Describing HOW not WHAT       | Task describes outcome, executor decides how |
| Unordered dependencies        | Tasks that block others must come first      |
| No version header             | Always include version, timestamp, status    |
| Skipping phases               | Group related tasks into logical phases      |
| Vague criteria like "works"   | Specific, verifiable conditions              |

## Validation Checklist

- [ ] Version header includes all required fields
- [ ] Each task has a numbered ID (X.Y format)
- [ ] Each code task has a `**File**:` field
- [ ] Each task has `**Done when**:` with checkboxes
- [ ] Tasks are atomic (completable in one session)
- [ ] Dependencies are ordered correctly
- [ ] Phases group related work logically
- [ ] Testing section lists verification approach
- [ ] Risks identified with mitigations
