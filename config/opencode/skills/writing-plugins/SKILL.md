---
name: writing-plugins
description: Use when creating, editing, or reviewing OpenCode plugins. Covers plugin structure, event hooks, TypeScript typing, custom tools, dependency management, and common patterns like notifications and compaction hooks.
---

# Writing Plugins

## Overview

Plugins extend OpenCode by hooking into events and customizing behavior. They're JavaScript/TypeScript modules that export functions receiving a context object and returning hooks.

## When to Use

- Creating event-driven automation (notifications, logging, protection)
- Adding custom tools to OpenCode
- Modifying tool behavior before/after execution
- Customizing session compaction behavior
- Integrating with external services

**Don't use for:** simple prompts (use commands), static configuration (use config), or agent behavior (use agents).

## File Locations

```
.opencode/plugin/<name>.js|ts       # Project-local
~/.config/opencode/plugin/<name>.js|ts  # Global/personal
```

Or via npm in `opencode.json`:

```json
{
  "plugin": ["opencode-helicone-session", "@my-org/custom-plugin"]
}
```

## Load Order

1. Global config (`~/.config/opencode/opencode.json`)
2. Project config (`opencode.json`)
3. Global plugin directory (`~/.config/opencode/plugin/`)
4. Project plugin directory (`.opencode/plugin/`)

## Basic Structure

```typescript
import type { Plugin } from "@opencode-ai/plugin";

export const MyPlugin: Plugin = async ({
  project,
  client,
  $,
  directory,
  worktree,
}) => {
  // Initialization code here

  return {
    // Hook implementations
  };
};
```

### Context Object

| Property    | Description                            |
| ----------- | -------------------------------------- |
| `project`   | Current project information            |
| `directory` | Current working directory              |
| `worktree`  | Git worktree path                      |
| `client`    | OpenCode SDK client for AI interaction |
| `$`         | Bun's shell API for executing commands |

## Event Hooks

### Event Categories

| Category   | Events                                                                                                                                          |
| ---------- | ----------------------------------------------------------------------------------------------------------------------------------------------- |
| Session    | `session.created`, `session.idle`, `session.compacted`, `session.deleted`, `session.error`, `session.status`, `session.updated`, `session.diff` |
| Tool       | `tool.execute.before`, `tool.execute.after`                                                                                                     |
| Message    | `message.updated`, `message.removed`, `message.part.updated`, `message.part.removed`                                                            |
| File       | `file.edited`, `file.watcher.updated`                                                                                                           |
| Permission | `permission.updated`, `permission.replied`                                                                                                      |
| TUI        | `tui.prompt.append`, `tui.command.execute`, `tui.toast.show`                                                                                    |
| LSP        | `lsp.client.diagnostics`, `lsp.updated`                                                                                                         |
| Other      | `command.executed`, `installation.updated`, `server.connected`, `todo.updated`                                                                  |

### Hook Patterns

```typescript
// Event subscription
return {
  event: async ({ event }) => {
    if (event.type === "session.idle") {
      // Handle event
    }
  },
};

// Tool interception
return {
  "tool.execute.before": async (input, output) => {
    // Modify or block tool execution
  },
  "tool.execute.after": async (input, output) => {
    // React to tool completion
  },
};
```

## Custom Tools

```typescript
import { type Plugin, tool } from "@opencode-ai/plugin";

export const CustomToolsPlugin: Plugin = async (ctx) => {
  return {
    tool: {
      mytool: tool({
        description: "This is a custom tool",
        args: {
          foo: tool.schema.string(),
        },
        async execute(args, ctx) {
          return `Hello ${args.foo}!`;
        },
      }),
    },
  };
};
```

## Dependencies

Add external packages via `.opencode/package.json`:

```json
{
  "dependencies": {
    "shescape": "^2.1.0"
  }
}
```

OpenCode runs `bun install` at startup. npm plugins are cached in `~/.cache/opencode/node_modules/`.

## Quick Reference

| Pattern                           | Example Use Case                      |
| --------------------------------- | ------------------------------------- |
| `event` handler                   | Notifications on `session.idle`       |
| `tool.execute.before`             | Block `.env` reads, sanitize commands |
| `tool.execute.after`              | Log tool usage, track metrics         |
| `tool` definition                 | Add domain-specific tools             |
| `experimental.session.compacting` | Custom compaction context             |

## Common Patterns

### Notification on Completion

```typescript
return {
  event: async ({ event }) => {
    if (event.type === "session.idle") {
      await $`osascript -e 'display notification "Done!" with title "opencode"'`;
    }
  },
};
```

### Tool Protection

```typescript
return {
  "tool.execute.before": async (input, output) => {
    if (input.tool === "read" && output.args.filePath.includes(".env")) {
      throw new Error("Do not read .env files");
    }
  },
};
```

### Structured Logging

```typescript
await client.app.log({
  service: "my-plugin",
  level: "info", // debug, info, warn, error
  message: "Plugin initialized",
  extra: { foo: "bar" },
});
```

### Compaction Context

```typescript
return {
  "experimental.session.compacting": async (input, output) => {
    // Add context (appended to default prompt)
    output.context.push(`## Custom Context\n...`);

    // OR replace entire prompt
    output.prompt = `Your custom compaction prompt...`;
  },
};
```

## Common Mistakes

| Mistake                          | Fix                                           |
| -------------------------------- | --------------------------------------------- |
| Using `console.log`              | Use `client.app.log()` for structured logging |
| Missing TypeScript types         | Import `Plugin` from `@opencode-ai/plugin`    |
| Throwing in hooks without intent | Throw to block, return to allow               |
| Forgetting async on handlers     | All hooks should be async functions           |
| Local deps without package.json  | Add `.opencode/package.json` for npm packages |

## Validation Checklist

- [ ] Plugin exports named function (not default)
- [ ] Function is async and returns hooks object
- [ ] TypeScript uses `Plugin` type import
- [ ] Event types checked before handling
- [ ] External deps listed in package.json
- [ ] Uses `client.app.log()` not `console.log`
- [ ] Tool definitions have description and args schema
