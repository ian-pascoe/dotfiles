# Dotfiles Repository

**Generated:** 2026-01-04 | **Commit:** cb2fde0 | **Branch:** master

## Overview

Cross-platform dotfiles for NixOS (WSL), nix-darwin (macOS), and Windows. Nix flake-based with home-manager integration, symlink-driven theming, and Unix parity layer for PowerShell.

## Structure

```
./
├── nix/              # Flake, hosts, homes, modules, lib (NOT at root)
├── config/           # App configs (symlinked by home-manager)
├── themes/           # 9 themes with backgrounds, app-specific files
├── Windows/          # PowerShell profile, scripts, GlazeWM, YASB
├── bin/              # User scripts
└── install.ps1       # Windows bootstrap entry
```

## Where to Look

| Task | Location | Notes |
|------|----------|-------|
| Add/modify host | `nix/hosts/{name}/` | Uses `lib.host.mkNixosSystem` or `mkDarwinSystem` |
| Add home config | `nix/homes/{user}@{host}/` | Uses `lib.home.mkHomeManagerConfig` |
| Add Nix module | `nix/modules/{common,nixos,darwin,home}/` | Auto-discovered via `lib.module.findModules` |
| Add app config | `config/{app}/` | Home-manager symlinks these |
| Add/edit theme | `themes/{name}/` | Run `set-theme {name}` after |
| Neovim plugins | `config/nvim/lua/plugins/` | LazyVim modular pattern |
| Sketchybar items | `config/sketchybar/items/` | Lua-based, OOP components |
| Windows scripts | `Windows/PowerShell/Scripts/` | PowerShell with Unix aliases |

## Commands

```bash
# Rebuild configurations
nrs                              # nixos-rebuild switch (alias)
nds                              # darwin-rebuild switch (alias)
nfu                              # nix flake update (alias)

# Full commands (require --impure for sops)
nixos-rebuild switch --flake .#Work-WSL --impure
darwin-rebuild switch --flake .#Personal-MacOS --impure

# Linting
biome check --write .            # JS/TS (double quotes, spaces)
stylua .                         # Lua (single quotes, 2 spaces, 160 col)

# Theming
set-theme <theme-name>           # Updates ~/.config/theme symlink
```

## Conventions

### Nix
- 2-space indent, nixpkgs style
- `imports = [ ... ];` at top
- Use custom lib wrappers: `lib.host.mkNixosSystem`, `lib.home.mkHomeManagerConfig`
- Modules auto-discovered - just add to correct directory

### Lua
- 2-space indent (StyLua enforced)
- Single quotes for strings
- `---@type` annotations for types
- `require()` at top, `local` for scope

### PowerShell
- PascalCase functions (e.g., `Update-PowerShell`)
- Approved verbs only (Get-, Set-, New-, Remove-)
- `-ErrorAction SilentlyContinue` for optional operations

## Anti-Patterns

- **NEVER** use `git add -A` or `git add .` - always explicit paths
- **NEVER** use limit/offset for file reads - need complete context
- **DO NOT** spawn sub-tasks before reading relevant files first
- **DO NOT** add packages via Mason - Nix manages all tools

## Platform-Specific

| Platform | Window Manager | Bar | Extra |
|----------|---------------|-----|-------|
| macOS | Aerospace | Sketchybar | Karabiner, Homebrew via nix-homebrew |
| NixOS/WSL | - | - | Terminal-focused |
| Windows | GlazeWM | YASB | PowerShell Unix parity layer |

~80% config shared via `modules/home/common`. Platform-specific in `modules/{darwin,nixos,home/{darwin,wsl}}`.

## Notes

- Flake is at `nix/flake.nix`, not root (clean root philosophy)
- RTX corp environments need PKI cert injection (see `nix/modules/home/rtx/`)
- Windows bootstrap: `install.ps1` → `setup.ps1` → `setup-wsl.sh`
- Theme symlink at `~/.config/theme` - apps read this dynamically
- Broken/TODO: nextcloud-client, sharkiq package, custom-python cleanup
