# Global Instructions

## Environment

- Chezmoi manages many files under `~`; their source is in `~/.local/share/chezmoi`, and `chezmoi apply` overwrites direct edits to a target.
- Global CLIs are declared in `~/.config/mise/config.toml`, itself chezmoi-managed; OS packages and libraries come from Homebrew, apt, or Scoop.
- Active projects are cloned into `~/src`, one directory per repo.
- Create git worktrees in the repo's `.worktrees/` when the repo gitignores it; otherwise in `~/.worktrees/<repo>/`.

## Subagent models

When you start a subagent or delegate a task, pick its model by the task:

- `anthropic/claude-haiku-5-5`: exploration (locating code, tracing behavior, finding reusable patterns), web and docs research, summarizing, mechanical edits. Medium thinking is usually enough.
- `anthropic/claude-sonnet-5-5`: well-specified work with a settled approach and clear acceptance criteria, such as one step of a reviewed plan, writing tests, or a scoped refactor.
- `anthropic/claude-opus-5-5`: the default workhorse. Medium thinking for implementation, work spanning several concerns, and anything not yet fully specified; high or xhigh thinking for debugging and regressions.
- `anthropic/claude-fable-5-2`: the last resort, at twice opus's per-token price. Planning and design, independent correctness or spec review, security audits, and debugging opus could not resolve. Keep its tasks focused: mostly reading code and returning a plan, verdict, or diagnosis.
