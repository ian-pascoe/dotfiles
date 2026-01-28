---
name: writing-commands
description: Use when creating, editing, or reviewing custom OpenCode commands. Covers frontmatter options, prompt templating with arguments and shell output, file references, and agent/model configuration.
---

# Writing Commands

## Overview

Commands are custom prompts triggered via `/command-name` in the TUI. They automate repetitive tasks with configurable agents, models, and dynamic prompt templating.

## When to Use

- Creating a new custom command for repetitive workflows
- Adding argument handling or shell output injection to commands
- Configuring which agent or model handles a command
- Converting inline prompts to reusable commands

**Don't use for:** one-off prompts, complex multi-step workflows (use agents), or logic that needs code execution.

## File Locations

```
.opencode/command/<name>.md         # Project-local
~/.config/opencode/command/<name>.md  # Global/personal
```

File name becomes the command name (e.g., `test.md` -> `/test`).

## Frontmatter Options

```yaml
---
description: Brief description shown in TUI
agent: build # Optional: agent to execute (default: current)
model: anthropic/... # Optional: override default model
subtask: true # Optional: force subagent invocation
---
```

| Option        | Required | Description                                      |
| ------------- | -------- | ------------------------------------------------ |
| `description` | No       | Shown in TUI command list                        |
| `agent`       | No       | Agent to execute (defaults to current)           |
| `model`       | No       | Override model for this command                  |
| `subtask`     | No       | Force subagent invocation (isolates context)     |
| `template`    | Yes\*    | Prompt text (JSON config only, body in markdown) |

\*In markdown files, the body after frontmatter IS the template.

## Prompt Templating

### Arguments

| Placeholder   | Description                    |
| ------------- | ------------------------------ |
| `$ARGUMENTS`  | All arguments as single string |
| `$1`, `$2`... | Positional arguments           |

```markdown
Create a React component named $1 in $2 directory.
```

Usage: `/component Button src/components`

### Shell Output

Inject command output with backtick syntax:

```markdown
Here are the current test results:
!`npm test`

Based on these results, suggest improvements.
```

Commands run from project root.

### File References

Include file contents with `@path`:

```markdown
Review the component in @src/components/Button.tsx.
Check for performance issues.
```

## Quick Reference

| Pattern           | Example                                     |
| ----------------- | ------------------------------------------- |
| Simple command    | `/test` -> runs test suite                  |
| With args         | `/component Button` -> `$1` = Button        |
| Shell injection   | `!`git log -5`` -> injects git output       |
| File inclusion    | `@src/index.ts` -> includes file content    |
| Subagent isolated | `subtask: true` -> runs in isolated context |

## JSON Config Alternative

Commands can also be defined in `opencode.jsonc`:

```jsonc
{
  "command": {
    "test": {
      "template": "Run tests with coverage...",
      "description": "Run tests with coverage",
      "agent": "build",
      "model": "anthropic/claude-3-5-sonnet-20241022",
    },
  },
}
```

## Common Mistakes

| Mistake                            | Fix                                                     |
| ---------------------------------- | ------------------------------------------------------- |
| Missing description                | Always add for TUI discoverability                      |
| Using `$ARGUMENTS` with positional | Pick one style: `$ARGUMENTS` OR `$1`, `$2`              |
| Shell commands with side effects   | Only use read-only commands in prompts                  |
| Overriding built-in without intent | Built-ins: `/init`, `/undo`, `/redo`, `/share`, `/help` |
| Forgetting quotes for JSON args    | `/cmd "{ \"key\": \"value\" }"`                         |

## Validation Checklist

- [ ] File name is lowercase, hyphen-separated
- [ ] Description is concise and descriptive
- [ ] Template uses correct placeholder syntax
- [ ] Shell commands are read-only (no mutations)
- [ ] File references use correct `@path` syntax
- [ ] Agent exists if specified
