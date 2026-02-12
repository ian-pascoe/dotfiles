# Global AGENTS.md Baseline Rules

These rules are safe defaults for most repositories. Apply them unless a project-local `AGENTS.md` or explicit user instruction overrides them.

## 1) Respect the repo first

- Follow existing project conventions (structure, naming, formatting, linting, test style).
- Prefer consistency with surrounding code over introducing personal patterns.

## 2) Keep changes minimal and focused

- Change only files needed for the requested task.
- Avoid drive-by refactors unless explicitly requested.
- Keep diffs easy to review.

## 3) Do not disturb unrelated work

- Never revert or rewrite user changes you did not make.
- If the git tree is dirty, ignore unrelated files and proceed carefully.

## 4) Safety and reversibility

- Do not run destructive commands (for example: `git reset --hard`, force push, bulk deletes) unless explicitly requested.
- For risky operations, prefer the safest reversible option.

## 5) Test proportionally

- Validate what you changed with the smallest relevant checks first.
- Run broader tests/build only when needed or requested.
- If you cannot run checks, state what was not verified.

## 6) Security and secrets

- Never commit secrets (API keys, tokens, credentials, private env files).
- Redact sensitive values in outputs and logs.

## 7) Dependency discipline

- Prefer existing dependencies and project utilities.
- Add new dependencies only when justified; mention why.

## 8) Clear communication

- Explain what changed, where, and why.
- Call out user-visible behavior changes and migration/setup impacts.
- Ask questions only when truly blocked by ambiguity or missing required values.

## 9) Commit quality

- Commit only when explicitly requested.
- Use focused commits with concise messages centered on intent (the "why").
- Do not include unrelated formatting or generated churn unless necessary.

## 10) Documentation and operability

- Update docs/config comments when behavior or setup changes.
- Provide concrete verification steps for the user to reproduce.

## 11) Skills

- Always evaluate the skills at your disposal and apply them appropriately to the task at hand.
- Do not attempt to use skills you do not have or that are not relevant to the task.

## 12) MCP-first via mcporter

- Always load the `mcporter` skill before performing MCP discovery or MCP tool calls.
- Prefer MCP tools via `mcporter` for external data/tasks.
- Before using non-MCP alternatives, run `mcporter list` and `mcporter list <server> --schema` when needed.
- For package intelligence tasks, use `packrun` via `mcporter` first.
- If `mcporter` fails or is unavailable, fall back to native CLI/web tools and state why.
- Always report which MCP server/tool was used.

## Precedence

1. Explicit user instruction
2. Project-local `AGENTS.md`
3. This global baseline
