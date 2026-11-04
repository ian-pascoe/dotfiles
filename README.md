# dotfiles

Ian Pascoe's dotfiles for macOS, Linux (including WSL) and Windows, managed with
[chezmoi](https://www.chezmoi.io/).

## Install

On a new machine, install chezmoi and apply these dotfiles in one step:

```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply ian-pascoe
```

On Windows (PowerShell):

```powershell
iex "&{$(irm 'https://get.chezmoi.io/ps1')} -- init --apply ian-pascoe"
```

If chezmoi is already installed:

```sh
chezmoi init --apply ian-pascoe
```

### Prerequisites

- [Git](https://git-scm.com/)
- [mise](https://mise.jdx.dev/): installs the global CLIs and runtimes after
  apply. Install it first and resolve any config trust prompts yourself.
- A native package manager: [Homebrew](https://brew.sh/) on macOS, APT on
  Linux, or [Scoop](https://scoop.sh/) on Windows.

## Update

```sh
chezmoi update      # pull the latest changes and apply them
chezmoi diff        # preview what apply would change
chezmoi apply       # apply the source state to $HOME
```

`upgrade-all` upgrades the packages installed by every package manager.

## What's inside

| Area              | Tools                                                                                                 |
| ----------------- | ----------------------------------------------------------------------------------------------------- |
| Shells            | Zsh, Bash, PowerShell, [Starship](https://starship.rs/) prompt                                        |
| Editor            | [Neovim](https://neovim.io/) ([LazyVim](https://www.lazyvim.org/))                                    |
| Terminals         | Ghostty, WezTerm, Windows Terminal, Tern, Rex, Herdr                                                  |
| Window management | AeroSpace, JankyBorders, Karabiner-Elements, Hammerspoon (macOS); GlazeWM, YASB, AutoHotkey (Windows) |
| CLI tools         | bat, btop, fastfetch, k9s, lsd, yazi, spotify-player                                                  |
| Coding agents     | [Pi](https://github.com/badlogic/pi-mono) config, extensions and skills; Plannotator                  |
| Themes            | 100+ coordinated themes with wallpapers, in light and dark variants                                   |

## Layout

chezmoi source names encode their target paths: `dot_config/` deploys to
`~/.config/`, `private_` sets restrictive permissions, `executable_` sets the
executable bit, and `.tmpl` files are rendered as templates.

| Path                         | Purpose                                                               |
| ---------------------------- | --------------------------------------------------------------------- |
| `dot_config/`                | `~/.config` app configuration                                         |
| `dot_local/bin/`             | Personal scripts: theme switching, package sync, maintenance          |
| `dot_themes/`                | Theme variants deployed to `~/.themes`                                |
| `dot_pi/`, `dot_agents/`     | Pi coding-agent config and installed agent skills                     |
| `.chezmoiscripts/`           | Post-apply hooks (see [docs/chezmoi-hooks.md](docs/chezmoi-hooks.md)) |
| `.chezmoiexternal.toml.tmpl` | Externally fetched assets, such as theme wallpapers                   |
| `.chezmoiignore`             | Repo-only files and per-OS exclusions                                 |
| `Brewfile`                   | macOS Homebrew packages                                               |
| `AppData/`, `Documents/`     | Windows-only configuration                                            |
| `Library/`                   | macOS-only configuration and LaunchAgents                             |
| `tern/`                      | Shared Tern config, included by each OS's config stub                 |
| `docs/`                      | Design notes, specs and research                                      |

## Packages

Shared CLI tools and runtimes are declared in
[`dot_config/mise/config.toml`](dot_config/mise/config.toml) and installed by a
post-apply hook. OS packages live in the native package manager's manifest:

- macOS: [`Brewfile`](Brewfile)
- Linux: [`dot_config/packages/private_apt.txt`](dot_config/packages/private_apt.txt)
- Windows: [`dot_config/scoop/scoopfile.json`](dot_config/scoop/scoopfile.json)

See [docs/package-ownership.md](docs/package-ownership.md) for which manager
owns what. `install-package-manifests` installs from the manifests, and
`sync-package-manifests` snapshots what each host has installed without
changing the manifests.

## Themes

Every themed app reads its theme through `~/.config/theme`, a link to the
active variant in `~/.themes/`. Switch themes with:

```sh
list-themes                       # list available themes
set-theme tokyo-night             # switch theme family, keeping the saved mode
set-theme gruvbox light           # switch family and mode
set-mode toggle                   # switch light/dark for the current theme
random-theme                      # pick a random theme
```

Windows has PowerShell equivalents (`Set-Theme.ps1`, `List-Themes.ps1`, ...).
To add a theme, see
[dot_themes/docs/adding-a-variant.md](dot_themes/docs/adding-a-variant.md).

## Development

Repo tooling (formatting, linting, tests for themes and scripts) is a
[pnpm](https://pnpm.io/) workspace:

```sh
pnpm install        # also installs the pre-commit hook
pnpm format         # oxfmt
pnpm lint           # oxlint
pnpm typecheck
pnpm test           # vitest
```

## Acknowledgements

- [chezmoi](https://www.chezmoi.io/) by Tom Payne
- Wallpaper sources and credits are listed in
  [`.chezmoiexternal.toml.tmpl`](.chezmoiexternal.toml.tmpl)

## License

My own work in this repo is licensed under the [MIT License](LICENSE).

Third-party content keeps its original license and is not covered by it:

- Agent skills in `dot_agents/skills/` from other authors; their sources are
  recorded in
  [`dot_local/state/skills/dot_skill-lock.json`](dot_local/state/skills/dot_skill-lock.json).
- Wallpapers, whether stored in `dot_themes/*/backgrounds/` or fetched via
  [`.chezmoiexternal.toml.tmpl`](.chezmoiexternal.toml.tmpl).
- Color palettes ported from upstream themes, which belong to their authors.
- Bible passages, which are public domain or CC0; see
  [docs/licenses/bible-translations.md](docs/licenses/bible-translations.md).
