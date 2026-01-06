---
description: Reviews the last commit made and determines if the plan was executed completely, and documents any drift that occurred during implementation. Provide a plan file in the arguments for the review to analyze. It is strongly advised to run this command within the session of a plan execution, after running commit.
---

# Review Plan Execution

Validate that an implementation plan was correctly executed, verify success criteria, and identify deviations.

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

### Step 3: Generate Report

Write to `thoughts/reviews/{plan-name}-review.md`:

```markdown
## Validation Report: [Plan Name]

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

### Step 4: Update Ticket

Set ticket frontmatter to `status: reviewed`

## Validation Checklist

- [ ] All phases marked complete are actually done
- [ ] Automated tests pass
- [ ] Code follows existing patterns
- [ ] No regressions introduced
- [ ] Error handling is robust

**Agent usage:**
- `explore` - Discovery and verification of file changes
- `oracle` - Self-review of implementation quality for complex changes (architecture, security, performance)

**review**

$ARGUMENTS
