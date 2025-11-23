# Agent Guidelines for Dotfiles Repository

## Build/Lint/Test Commands

- **Lint Lua/JS/TS**: `biome check --write .` (formats with spaces, double quotes for JS/TS)
- **Format Lua**: `stylua .` (2 spaces, Unix line endings, single quotes preferred)
- **Rebuild NixOS (WSL)**: `nixos-rebuild switch --flake .#Work-WSL`
- **Rebuild Darwin (MacOS)**: `darwin-rebuild switch --flake .#Personal-MacOS`
- **No formal tests**: This is a dotfiles repo; test by rebuilding configurations

## Code Style Guidelines

### Nix

- Use 2-space indentation, follow nixpkgs style
- Organize imports at top: `imports = [ ... ];`
- Use functional approach with attribute sets

### PowerShell

- PascalCase for functions (e.g., `Update-PowerShell`)
- Use approved verbs (Get-, Set-, New-, Remove-)
- Include error handling with `-ErrorAction SilentlyContinue` where appropriate
- Document with param blocks and comments

### Lua

- Use 2-space indentation (StyLua enforced)
- Prefer single quotes for strings
- Use `---@type` annotations for types
- Organize requires at top: `require("module")`
- Use `local` for scoped variables

### General

- Keep configurations modular and organized by tool/category
- Use symlinks for shared configs across platforms
- Platform-specific code in separate modules (darwin/, nixos/, wsl/)
