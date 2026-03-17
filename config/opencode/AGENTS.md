# AGENTS.md - Global Instructions

## Context Handling

### Mandatory Note-Taking

- Treat any user statement matching "always", "never", "from now on", "preference", "when X do Y", or correction of agent behavior as a standing instruction candidate.
- If the instruction is expected to apply beyond the current single task, update `AGENTS.md` in the same session before sending the final response.
- Do not say "noted" unless the `AGENTS.md` edit is already made.
- In the response where the note is recorded, include the exact file path (`AGENTS.md`) and what was added.
- If uncertain whether an instruction is standing or one-off, default to recording it in `AGENTS.md`.

### Completion Checklist

- Confirm whether any new standing preference appeared during the conversation.
- If yes, update `AGENTS.md` first, then respond.
- If no, avoid claiming that anything was "noted".

### Standing Preferences

- Use Conventional Commit messages when creating commits.

## Skills

- **Always** consider whether any skills apply to the task at hand.
- If multiple skills could apply, load the best one and start there. Progressively load more skills as needed.

---

This file is for you. If you need to update it, do it. Don't ask for permission to update this file.
