---
name: writing-agents
description: Use when creating, editing, or reviewing agent configuration files (AGENT.md or opencode.json agents). Covers frontmatter options, mode selection, tool permissions, and common patterns.
---

# Writing Agents

## Overview

Agents are specialized AI assistants with custom prompts, models, and tool access. Configure via markdown files or JSON.

## When to Use

- Creating a new agent for specific tasks
- Editing agent prompts, permissions, or tool access
- Choosing between primary vs subagent mode
- Setting up task permissions for orchestration
- Reviewing agent configuration quality

**Don't use for:** skill files (use `writing-skills`), system prompts without agent context, or MCP server config.

## File Locations

```
~/.config/opencode/agent/<name>.md     # Global agents
.opencode/agent/<name>.md              # Project-local agents
opencode.json → agent.<name>           # JSON config (either location)
```

Filename becomes agent name (e.g., `review.md` → `review` agent).

## Frontmatter Reference

| Field         | Required | Values                       | Notes                                     |
| ------------- | -------- | ---------------------------- | ----------------------------------------- |
| `description` | Yes      | string                       | Brief description for agent selection     |
| `mode`        | No       | `primary`, `subagent`, `all` | Default: `all`                            |
| `model`       | No       | `provider/model-id`          | Inherits from parent if unset             |
| `temperature` | No       | 0.0-1.0                      | 0.0-0.2 focused, 0.6-1.0 creative         |
| `maxSteps`    | No       | integer                      | Limit agentic iterations                  |
| `hidden`      | No       | boolean                      | Hide from @ autocomplete (subagents only) |
| `disable`     | No       | boolean                      | Disable the agent                         |
| `tools`       | No       | object                       | Enable/disable specific tools             |
| `permission`  | No       | object                       | Configure ask/allow/deny per tool         |

## Mode Selection

| Mode       | Use Case                                    |
| ---------- | ------------------------------------------- |
| `primary`  | Main agents user switches between (Tab key) |
| `subagent` | Invoked by primary agents or via @ mention  |
| `all`      | Available in both contexts (default)        |

## Tool Configuration

```yaml
tools:
  write: false # Disable write tool
  edit: false # Disable edit tool
  bash: false # Disable bash tool
  mymcp_*: false # Wildcards for MCP tools
```

## Permission Configuration

```yaml
permission:
  edit: deny # deny | ask | allow
  bash:
    "*": ask # Default for all commands
    "git status": allow # Specific command override
    "git push*": ask # Glob patterns supported
  webfetch: deny
  task:
    "*": deny # Block all subagent invocation
    "my-helper-*": allow # Allow specific subagents
```

**Rule evaluation:** Last matching rule wins. Put `*` first, specifics after.

## Markdown Template

```markdown
---
description: <what it does and when to use>
mode: subagent
model: anthropic/claude-sonnet-4-20250514
temperature: 0.1
tools:
  write: false
  edit: false
  bash: false
permission:
  edit: deny
---

<system prompt content>

Focus on:

- Point 1
- Point 2
```

## JSON Template

```json
{
  "agent": {
    "my-agent": {
      "description": "What it does",
      "mode": "subagent",
      "model": "anthropic/claude-sonnet-4-20250514",
      "prompt": "{file:./prompts/my-agent.txt}",
      "tools": {
        "write": false,
        "edit": false
      },
      "permission": {
        "bash": {
          "*": "ask",
          "git diff": "allow"
        }
      }
    }
  }
}
```

## Common Patterns

### Read-Only Reviewer

```yaml
tools:
  write: false
  edit: false
  bash: false
```

### Restricted Bash Access

```yaml
permission:
  bash:
    "*": ask
    "git status": allow
    "git log*": allow
    "git diff*": allow
```

### Orchestrator with Task Limits

```yaml
permission:
  task:
    "*": deny
    "my-workers-*": allow
```

## Common Mistakes

| Mistake                            | Fix                                             |
| ---------------------------------- | ----------------------------------------------- |
| Missing description                | Always provide clear description                |
| Using `hidden` on primary agent    | `hidden` only works on subagents                |
| Expecting `*` to be evaluated last | Last rule wins - put `*` first                  |
| Setting model on subagent          | Subagents inherit parent model if unset         |
| Narrative prompt style             | Focus on role and constraints, not conversation |

## Validation Checklist

- [ ] Description clearly states purpose and trigger conditions
- [ ] Mode matches intended usage (primary vs subagent)
- [ ] Tools restricted appropriately for the role
- [ ] Permissions use correct ask/allow/deny values
- [ ] Bash permission rules ordered correctly (`*` first)
- [ ] Prompt focuses on role, constraints, and focus areas
