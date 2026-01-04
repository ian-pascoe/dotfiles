# Neovim Configuration

## Overview

LazyVim-based config with Nix-managed tools (Mason disabled), dynamic theming via symlink.

## Structure

```
nvim/
├── init.lua          # Bootstrap only (loads config.lazy)
├── lua/
│   ├── config/       # Core config (lazy.lua, keymaps, options)
│   ├── plugins/      # Modular plugin specs (one per file)
│   └── util/         # Helpers (get_theme(), etc.)
└── after/            # Filetype-specific overrides
```

## Where to Look

| Task | Location |
|------|----------|
| Add plugin | `lua/plugins/{name}.lua` - return spec table |
| Modify keymaps | `lua/config/keymaps.lua` |
| Change options | `lua/config/options.lua` |
| Add filetype config | `after/ftplugin/{filetype}.lua` |

## Conventions

- **Theme**: `Util.get_theme()` reads `~/.config/theme` symlink
- **File navigation**: Oil.nvim + yazi.nvim (not neo-tree)
- **Completion**: Copilot disabled on `.env` files
- **Windows**: Auto-switches to pwsh shell

## Anti-Patterns

- **NEVER** add packages via Mason - Nix manages LSPs/formatters
- **DO NOT** hardcode theme colors - use dynamic theme loading
- **DO NOT** use setup() in plugin files - return LazyVim spec tables
