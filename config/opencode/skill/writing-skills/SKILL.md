---
name: writing-skills
description: Use when creating, editing, or reviewing SKILL.md files for AI agents. Covers frontmatter requirements, naming conventions, structure patterns, and common mistakes.
---

# Writing Skills

## Overview

Skills are reusable reference guides that help AI agents find and apply effective techniques. A skill is NOT a narrative - it's a pattern, technique, or reference that applies broadly.

## When to Use

- Creating a new skill from a discovered technique
- Editing or improving an existing skill
- Reviewing skill quality before deployment
- Unsure if something should be a skill vs project-specific docs

**Don't create skills for:** one-off solutions, project-specific conventions (use AGENTS.md), or things enforceable via automation.

## File Structure

```
.opencode/skill/<name>/SKILL.md     # Project-local
~/.config/opencode/skill/<name>/    # Global/personal
```

Directory name MUST match the `name` field in frontmatter.

## Frontmatter Requirements

Only two fields are recognized:

```yaml
---
name: skill-name-here
description: Use when [specific triggering conditions and symptoms]
---
```

**Name rules:**

- 1-64 characters
- Lowercase alphanumeric with single hyphens
- No leading/trailing hyphens, no consecutive `--`
- Regex: `^[a-z0-9]+(-[a-z0-9]+)*$`

**Description rules:**

- 1-1024 characters (aim for <500)
- Start with "Use when..." - focus on triggers, not workflow
- Third person (injected into system prompt)
- NEVER summarize the skill's process

## Quick Reference

| Element | Requirement | Example |
|---------|-------------|---------|
| Name | lowercase, hyphenated, 1-64 chars | `condition-based-waiting` |
| Description | "Use when..." + triggers only | "Use when tests flake due to timing" |
| Overview | 1-2 sentences, core principle | What + Why |
| When to Use | Symptoms + exclusions | Include "Don't use for" |
| Quick Reference | Scannable table | Most-needed info at a glance |
| Common Mistakes | Table format | Mistake \| Fix |
| Validation Checklist | Checkboxes | Final quality gate |

## Document Structure

```markdown
## Overview

Core principle in 1-2 sentences.

## When to Use

Symptoms and triggering conditions.
When NOT to use.

## Core Pattern

Before/after or key technique.

## Quick Reference

Table or bullets for scanning.

## Common Mistakes

What goes wrong + fixes.
```

## Common Mistakes

| Mistake                          | Fix                                         |
| -------------------------------- | ------------------------------------------- |
| Description summarizes workflow  | Only include triggering conditions          |
| Generic name like `helper-utils` | Use active voice: `condition-based-waiting` |
| Narrative storytelling           | Extract reusable pattern                    |
| Multiple mediocre examples       | One excellent, complete example             |
| Heavy content inline             | Split to supporting files if >100 lines     |

## Validation Checklist

- [ ] Name matches directory and follows naming rules
- [ ] Description starts with "Use when..."
- [ ] Description does NOT summarize the skill's workflow
- [ ] Written in third person
- [ ] Includes triggering symptoms/conditions
- [ ] Has quick reference for scanning
- [ ] No narrative or session-specific content
