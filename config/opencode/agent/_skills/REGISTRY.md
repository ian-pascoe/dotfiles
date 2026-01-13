# Skill Registry

Reference this registry before complex tasks. If your task matches a pattern, load the skill for detailed guidance.

## How to Use Skills

1. **Scan patterns** below for your current task
2. **Load skill** via `mcp_skill` tool: `mcp_skill(name: "<skill-name>")`
3. **Apply guidance** from the loaded skill throughout your work

Skills are loaded on-demand - only load when patterns match your task.

---

## Git & Version Control

| Trigger Pattern                      | Skill                    | Primary Agent |
| ------------------------------------ | ------------------------ | ------------- |
| Interactive rebase, history cleanup  | `git-advanced-workflows` | executor      |
| Cherry-pick commits between branches | `git-advanced-workflows` | executor      |
| Git bisect for bug hunting           | `git-advanced-workflows` | executor      |
| Worktrees for parallel development   | `git-advanced-workflows` | executor      |
| Reflog recovery, undo mistakes       | `git-advanced-workflows` | executor      |
| Complex merge conflict resolution    | `git-advanced-workflows` | executor      |

## Frontend Development

| Trigger Pattern                | Skill             | Primary Agent |
| ------------------------------ | ----------------- | ------------- |
| Build web UI, component, page  | `frontend-design` | executor      |
| Create application interface   | `frontend-design` | executor      |
| Design system implementation   | `frontend-design` | executor      |
| Production-grade frontend work | `frontend-design` | executor      |

## LLM & Prompt Engineering

| Trigger Pattern                 | Skill                         | Primary Agent |
| ------------------------------- | ----------------------------- | ------------- |
| Design LLM system prompts       | `prompt-engineering-patterns` | architect     |
| Optimize prompts for production | `prompt-engineering-patterns` | architect     |
| Few-shot learning patterns      | `prompt-engineering-patterns` | architect     |
| Chain-of-thought reasoning      | `prompt-engineering-patterns` | architect     |
| Prompt template design          | `prompt-engineering-patterns` | planner       |

## OpenCode Configuration

| Trigger Pattern             | Skill              | Primary Agent |
| --------------------------- | ------------------ | ------------- |
| Create/edit SKILL.md files  | `writing-skills`   | documenter    |
| Create/edit agent .md files | `writing-agents`   | documenter    |
| Create/edit custom commands | `writing-commands` | documenter    |
| Create/edit plugins         | `writing-plugins`  | documenter    |
| Create/edit custom tools    | `writing-tools`    | documenter    |

---

## Adding New Skills

When creating a new skill:

1. Create the skill in `skill/<name>/SKILL.md`
2. Add a row to the appropriate section above
3. Specify trigger patterns and primary agent

Skills should have descriptions starting with "Use when..." for consistency.
