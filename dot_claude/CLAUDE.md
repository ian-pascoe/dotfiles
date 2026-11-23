# Global Instructions

## Environment

- Chezmoi manages many files under `~`; their source is in `~/.local/share/chezmoi`, and `chezmoi apply` overwrites direct edits to a target.
- Global CLIs are declared in `~/.config/mise/config.toml`, itself chezmoi-managed; OS packages and libraries come from Homebrew, apt, or Scoop.
- `sed` is GNU sed on every machine (Homebrew's gnu-sed on macOS), so an in-place edit is `sed -i`, with no `''` after it.
- The Bash tool's shell is zsh: brace every variable (`${SHA}:refs/heads/x`), since zsh reads `$SHA:r` as a modifier, quote a glob meant for the command (`--include='*.ts'`), and run a script that relies on word-splitting under `bash -c`.
- Active projects are cloned into `~/src`, one directory per repo.
- Create git worktrees in the repo's `.worktrees/` when the repo gitignores it; otherwise in `~/.worktrees/<repo>/`.

## Subagent models

When you start a subagent with the `Agent` tool, pick its `model` by the task. These instructions explicitly ask for the effort levels named below, so pass them as the `Agent` tool's `effort`.

- `haiku`: exploration (locating code, tracing behavior, finding reusable patterns), web and docs research, summarizing, mechanical edits. `medium` effort is usually enough.
- `sonnet`: well-specified work with a settled approach and clear acceptance criteria, such as one step of a reviewed plan, writing tests, or a scoped refactor.
- `opus`: the default workhorse. `medium` effort for implementation, work spanning several concerns, and anything not yet fully specified; `high` or `xhigh` effort for debugging and regressions.
- `fable`: the last resort, at twice opus's per-token price. Planning and design, independent correctness or spec review, security audits, and debugging opus could not resolve. Keep its tasks focused: mostly reading code and returning a plan, verdict, or diagnosis.
