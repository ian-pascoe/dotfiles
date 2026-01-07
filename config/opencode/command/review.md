---
description: Reviews the last commit made and determines if the plan was executed completely, and documents any drift that occurred during implementation. Provide a plan file in the arguments for the review to analyze. It is strongly advised to run this command within the session of a plan execution, after running commit.
---

# Review Plan Execution

Validate that an implementation plan was correctly executed, verify success criteria, and identify deviations.

## TODO CREATION (MANDATORY)

**IMMEDIATELY** create a todo list before any other action:

```
1. Read implementation plan
2. Gather context (session or explore agents)
3. Validate each phase systematically
4. Code cleanup (debug code, unused imports, formatting)
5. Generate review report
6. Update beads status and create follow-ups
7. Run bd sync
```

Use `todowrite` to create these items, then mark each `in_progress` as you work and `completed` when done.

## Process

### Step 1: Context Discovery

1. **Read the implementation plan** completely
2. **Leverage session context** - If this follows /execute, you already know what was done
3. **Identify expected changes** - Files modified, success criteria, key functionality
4. **Fire parallel explore agents** to verify (only if not already in session context):
   - Database/schema changes match plan
   - Code changes match specifications
   - Tests were added/modified as specified

### Step 2: Systematic Validation

For each phase:

1. **Check completion** - Verify checkmarks match actual code
2. **Run automated verification** - Execute commands from success criteria
3. **List manual criteria** - Provide clear steps for user verification
4. **Consider edge cases** - Error handling, missing validations, regressions

### Step 3: Code Cleanup

Before finalizing, clean up implementation artifacts:

1. **Remove debug code**:
   - `console.log`, `print()`, `debugger` statements
   - Temporary test values or hardcoded data
   - Development-only comments (`// TODO: remove`, `// FIXME`, `// DEBUG`)

2. **Clean up imports and dependencies**:
   - Remove unused imports (use `lsp_code_actions` with `source.organizeImports`)
   - Remove unused variables and functions
   - Check for accidentally added dev dependencies in production

3. **Fix formatting and linting**:
   - Run project linter/formatter if configured
   - Fix any new lint errors introduced by changes
   - Ensure consistent code style with existing codebase

4. **Verify no accidental changes**:
   - Check for unintended file modifications
   - Ensure no test files contain skipped tests (`.skip`, `@pytest.mark.skip`)
   - Confirm no commented-out code blocks left behind

### Step 4: Generate Report

Write to `thoughts/reviews/{plan-name}-review.md`:

```markdown
## Validation Report: [Plan Name]

### Beads Reference
- Original Issue: `<beads-id>`
- Follow-up Issues Created: `<beads-id>`, `<beads-id>` (if any)

### Implementation Status
✓ Phase 1: [Name] - Fully implemented
⚠️ Phase 2: [Name] - Partially implemented (see issues)

### Automated Verification Results
✓ `command` - passed
✗ `command` - failed (details)

### Code Review Findings

#### Matches Plan:
- [What was implemented correctly]

#### Deviations from Plan:
- Phase [N]: [Original vs actual, assessment, recommendation]

#### Potential Issues:
- [Concerns discovered]

### Manual Testing Required:
- [ ] [Verification step]

### Recommendations:
- [Action items]
```

### Step 5: Update Status & Create Follow-ups

1. If implementation is complete and verified:
   - Close the beads issue: `bd close <id> --reason="Implementation complete and verified"`
   - Set ticket frontmatter to `status: reviewed`

2. If issues were found:
   - Create follow-up beads issues: `bd create --title="Fix: [issue]" --type=bug`
   - Link to original: `bd dep add <new-id> <original-id> --type=discovered-from`
   - Document in review report

3. Sync: `bd sync`

## Validation Checklist

- [ ] All phases marked complete are actually done
- [ ] Automated tests pass
- [ ] Code follows existing patterns
- [ ] No regressions introduced
- [ ] Error handling is robust

## Agent Usage

- **explore** - Verify file changes match plan
- **oracle** - Self-review for complex implementations (REQUIRED for: auth/security, data migrations, API contracts, performance-critical code)

## Quality Checklist

Before closing, verify:

- [ ] No `as any`, `@ts-ignore`, or type suppressions added
- [ ] Error handling: no empty catch blocks
- [ ] Secrets: no hardcoded credentials, tokens, or keys
- [ ] Tests: coverage for new functionality
- [ ] Patterns: follows existing codebase conventions

**review**

$ARGUMENTS
