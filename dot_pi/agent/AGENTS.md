# Global Instructions

## Environment

- Chezmoi manages many files under `~`; their source is in `~/.local/share/chezmoi`, and `chezmoi apply` overwrites direct edits to a target.
- Global CLIs are declared in `~/.config/mise/config.toml`, itself chezmoi-managed; OS packages and libraries come from Homebrew, apt, or Scoop.
