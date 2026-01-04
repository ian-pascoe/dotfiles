# Sketchybar Configuration

## Overview

Lua-based sketchybar config (not shell). OOP components, dynamic theming, Aerospace integration.

## Structure

```
sketchybar/
├── sketchybarrc.lua  # Entry point
├── init.lua          # Core setup
├── config/
│   ├── colors.lua    # Loads theme from symlink
│   └── themes/       # Semantic color mappings per theme
├── items/            # Bar items (brackets group visually)
├── components/       # OOP base classes (button.lua)
└── helpers/
    └── event_providers/  # C helpers for events
```

## Where to Look

| Task | Location |
|------|----------|
| Add bar item | `items/{name}.lua` |
| Modify colors | `config/themes/{theme}.lua` (semantic) |
| Add component type | `components/{type}.lua` |
| Add event provider | `helpers/event_providers/` (C) |

## Conventions

- **Theme**: Colors from `~/.config/theme` symlink via `config/colors.lua`
- **Brackets**: Visual grouping in items/ (e.g., `[item1, item2]`)
- **Aerospace**: Deep integration for workspace display
- **OOP**: Extend `components/button.lua` for new item types

## Anti-Patterns

- **DO NOT** hardcode hex colors - use semantic theme values
- **DO NOT** use shell scripts - this is Lua-native sketchybar
