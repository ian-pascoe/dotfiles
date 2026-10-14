# Theme variants are sibling folders grouped into families; the mode is ours, not the apps'

Light and dark versions of a theme are complete, separate theme folders (such as
`catppuccin` and `catppuccin-latte`), grouped into a family by a `family` file in
each, rather than `light/` and `dark/` subfolders of one family folder.
Neovim, the Pi extension, the hunk mapping, fastfetch, `get-theme`,
`Set-Theme.ps1` and the yazi flavor links all read the theme's name from the
`~/.config/theme` link. Sibling folders keep that name unique and meaningful,
so none of them change.

The mode is a per-machine setting that `set-theme` and `set-mode` own; the OS
appearance follows it, not the other way round. Apps' own light/dark features
(Ghostty `light:/dark:`, yazi `[flavor] light/dark`, Tern
`theme_light/theme_dark`, herdr `auto_switch`) are deliberately unused. Each
variant sets one value, so the link alone decides every app's colors. Mixing
in apps that follow the system appearance by themselves is what left Ghostty
light while everything else stayed dark.

## Considered Options

- **Subfolders per mode** (`catppuccin/{dark,light}/`): the link's basename
  would become `dark` or `light`, breaking every reader above; rejected.
- **Follow the OS appearance live**: needs a watcher to re-theme the apps that
  can't follow it themselves (bat, btop, k9s, borders, …). It can be layered on
  later as a watcher that calls `set-mode`.
