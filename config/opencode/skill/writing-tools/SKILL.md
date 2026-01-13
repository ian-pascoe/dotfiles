---
name: writing-tools
description: Use when creating, editing, or reviewing custom OpenCode tools. Covers tool definition structure, argument schemas with Zod, context access, multi-tool files, and invoking scripts in other languages.
---

# Writing Custom Tools

## Overview

Custom tools are TypeScript/JavaScript definitions that let the LLM call your functions during conversations. The definition is always TS/JS, but can invoke scripts in any language.

## When to Use

- Creating a new tool for LLM to call
- Editing or improving an existing tool
- Reviewing tool quality and argument schemas
- Wrapping scripts in other languages (Python, Bash, etc.)

**Don't use for:** MCP servers (different pattern), plugins (use plugin hooks), or built-in tool configuration.

## File Structure

```
.opencode/tool/<name>.ts     # Project-local
~/.config/opencode/tool/     # Global/personal
```

Filename becomes the tool name. Multiple exports create `<filename>_<exportname>` tools.

## Core Pattern

### Single Tool (Default Export)

```typescript
import { tool } from "@opencode-ai/plugin";

export default tool({
  description: "What this tool does",
  args: {
    param: tool.schema.string().describe("Parameter description"),
  },
  async execute(args) {
    // Implementation
    return "result";
  },
});
```

### Multiple Tools (Named Exports)

```typescript
import { tool } from "@opencode-ai/plugin";

export const add = tool({
  description: "Add two numbers",
  args: {
    a: tool.schema.number().describe("First number"),
    b: tool.schema.number().describe("Second number"),
  },
  async execute(args) {
    return args.a + args.b;
  },
});

export const subtract = tool({
  description: "Subtract two numbers",
  args: {
    a: tool.schema.number().describe("First number"),
    b: tool.schema.number().describe("Second number"),
  },
  async execute(args) {
    return args.a - args.b;
  },
});
```

Creates tools: `math_add` and `math_subtract` (if file is `math.ts`).

## Quick Reference

| Element       | Type                   | Notes                            |
| ------------- | ---------------------- | -------------------------------- |
| `description` | string                 | Required. What the tool does     |
| `args`        | object                 | Zod schemas via `tool.schema.*`  |
| `execute`     | async function         | Receives `(args, context)`       |
| Return value  | string, number, object | Serializable result shown to LLM |

### Argument Types (Zod)

```typescript
tool.schema.string(); // String
tool.schema.number(); // Number
tool.schema.boolean(); // Boolean
tool.schema.array(tool.schema.string()); // Array
tool.schema.object({ key: tool.schema.string() }); // Object
tool.schema.enum(["a", "b"]); // Enum
tool.schema.string().optional(); // Optional
tool.schema.string().default("x"); // Default value
```

Always add `.describe("...")` to each argument.

### Context Object

```typescript
async execute(args, context) {
  const { agent, sessionID, messageID } = context
  // Use context as needed
}
```

## Invoking Other Languages

Tool definitions are TS/JS, but can call any script:

```typescript
import { tool } from "@opencode-ai/plugin";

export default tool({
  description: "Run Python script",
  args: {
    input: tool.schema.string().describe("Input to process"),
  },
  async execute(args) {
    const result =
      await Bun.$`python3 .opencode/tool/script.py ${args.input}`.text();
    return result.trim();
  },
});
```

Use `Bun.$` for shell commands with proper escaping.

## Common Mistakes

| Mistake                       | Fix                                        |
| ----------------------------- | ------------------------------------------ |
| Missing `.describe()` on args | Always describe what each argument expects |
| Vague description             | Be specific about what the tool does       |
| Returning non-serializable    | Return strings, numbers, or plain objects  |
| Sync execute function         | Always use `async execute`                 |
| Hardcoded paths               | Use relative paths or context              |

## Validation Checklist

- [ ] File is `.ts` or `.js` in correct location
- [ ] Has `description` field
- [ ] All args have `.describe()` calls
- [ ] Execute function is async
- [ ] Returns serializable value
- [ ] Default export for single tool, named exports for multiple
