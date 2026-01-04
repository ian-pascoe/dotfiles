# Nix Configuration

## Overview

Flake-based Nix config with custom lib abstractions, auto-discovered modules, and host/home separation.

## Structure

```
nix/
├── flake.nix         # Entry point (NOT at repo root)
├── lib/              # Custom wrappers (host, home, module helpers)
├── hosts/            # Machine configs (NixOS, Darwin)
├── homes/            # Home-manager configs ({user}@{host}/)
├── modules/          # Auto-discovered modules
│   ├── common/       # Shared (NixOS + Darwin)
│   ├── nixos/        # NixOS-only
│   ├── darwin/       # Darwin-only
│   └── home/         # Home-manager modules
│       ├── common/   # ~80% of config lives here
│       ├── darwin/   # macOS-specific home
│       ├── wsl/      # WSL-specific home
│       └── rtx/      # Corp PKI cert injection
└── secrets/          # sops-nix encrypted secrets
```

## Where to Look

| Task | Location |
|------|----------|
| Add new host | `hosts/{name}/default.nix` → use `lib.host.mkNixosSystem` or `mkDarwinSystem` |
| Add home config | `homes/{user}@{host}/default.nix` → use `lib.home.mkHomeManagerConfig` |
| Add shared module | `modules/common/` or `modules/home/common/` |
| Add platform module | `modules/{nixos,darwin}/` or `modules/home/{darwin,wsl}/` |
| Modify lib helpers | `lib/*.nix` |

## Conventions

- Modules auto-discovered via `lib.module.findModules` - just add files
- Host naming: `{Name}-{Platform}` (e.g., `Ians-MacbookPro`, `Work-WSL`)
- Home naming: `{user}@{host}` pattern
- `--impure` required for sops secrets

## Anti-Patterns

- **NEVER** add to flake inputs without checking existing ones
- **DO NOT** duplicate between hosts - extract to modules
- **DO NOT** bypass lib wrappers with raw mkNixosConfiguration
