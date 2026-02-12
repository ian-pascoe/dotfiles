# AGENTS.md - Global Instructions for Agents

## Context Handling

### Mandatory Note-Taking Protocol

- Treat any user statement matching "always", "never", "from now on", "preference", "when X do Y", or correction of agent behavior as a standing instruction candidate.
- If the instruction is expected to apply beyond the current single task, update `AGENTS.md` in the same session before sending the final response.
- Do not say "noted" unless the `AGENTS.md` edit is already made.
- In the response where the note is recorded, include the exact file path (`AGENTS.md`) and what was added.
- If uncertain whether an instruction is standing or one-off, default to recording it in `AGENTS.md`.

### Completion Checklist (Before Final Response)

- Confirm whether any new standing preference appeared during the conversation.
- If yes, update `AGENTS.md` first, then respond.
- If no, avoid claiming that anything was "noted".

## Using Skills

### Rules

- **EXTREMELY IMPORTANT:** If you think there is even a 0.1% chance a skill might apply to what you are doing, you ABSOLUTELY MUST invoke the skill.
- **IF A SKILL APPLIES TO YOUR TASK, YOU DO NOT HAVE A CHOICE. YOU MUST USE IT.**
- **This is not negotiable. This is not optional.** You cannot rationalize your way out of this.

### Important Skills

- `mcporter`: **ALWAYS CHECK FIRST**. Access to MCP (Model Context Protocol) servers using a clean CLI. There are several MCP servers available, you should always inspect these to discover available tools.
- `simplify`: Load this skill after writing code to simplify and optimize it.

---

This file is for you. If you need to update it, do it.
