# Repository Guidelines

## Project Structure & Module Organization

This repository is a cross-platform dotfiles setup.

- `config/`: primary managed configs (for example `config/hammerspoon/`, `config/nvim/`, `config/zsh/`, `config/jj/`).
- `themes/`: theme variants and assets (Nord, Tokyo Night, Catppuccin, Rose Pine).
- `bin/`: helper scripts for theme/background and system utilities.
- `Windows/`: Windows and WSL setup scripts and profiles.
- Root installers: `install.sh` (macOS/Linux) and `install.ps1` (Windows).
- Focused test suites live under `config/opencode/superpowers/tests/`.

## Build, Test, and Development Commands

- `./install.sh`: install/symlink dotfiles on Unix-like systems.
- `./install.sh --dry-run --strict`: preview all installer actions and fail on optional-step errors.
- `./install.ps1`: Windows installer.
- `bash config/opencode/superpowers/tests/opencode/run-tests.sh`: run OpenCode plugin tests.
- `bash config/opencode/superpowers/tests/opencode/run-tests.sh --integration`: include integration tests.
- `bunx @biomejs/biome check config/opencode`: lint/format checks for the OpenCode TypeScript area.

## Coding Style & Naming Conventions

- Follow `.editorconfig`: LF line endings, spaces, 2-space indentation.
- Shell scripts should start with `#!/usr/bin/env bash` and use strict mode (`set -euo pipefail` or stronger).
- Prefer descriptive, kebab-case file names for scripts (for example `set-theme`, `run-tests.sh`).
- In `config/opencode`, follow Biome defaults: single quotes, trailing commas, and import organization.

## Testing Guidelines

- Primary automated tests are shell-based and concentrated in `config/opencode/superpowers/tests/`.
- Keep test scripts executable and named `test-*.sh`.
- Run targeted suites first, then broader suites with `--integration` when relevant.
- For installer changes, validate with `./install.sh --dry-run` before real execution.

## Commit & Pull Request Guidelines

- This repo is `jj`-first: use `jj status`, `jj diff`, `jj log`, and `jj describe`.
- Recent history shows short subjects (for example `updates`); prefer clear imperative summaries like `hammerspoon: sync caffeinate with power source`.
- Keep commits scoped to one logical change.
- PRs should include: intent, affected paths, verification commands run, and screenshots for visual config/UI changes.

## Security & Configuration Tips

- Never commit secrets, tokens, or machine-specific private keys.
- Review platform-specific scripts before running with elevated privileges.
- Prefer dry runs and explicit flags when changing system-level config.
