# Helium

Each variant's `helium/manifest.json` is a Chromium theme extension, written
by the generator. Helium loads it unpacked from `~/.local/state/helium-theme`,
a real folder holding a copy. It can't load `~/.config/theme/helium` because
Chromium resolves links when it loads an unpacked extension, and the
extension's ID comes from the resolved path.

On a theme switch, `set-theme` (through `helium-theme`) and `Set-Theme.ps1`
copy the manifest into that folder. They also delete `Cached Theme.pak`,
Chromium's compiled theme, because Helium starts from that file whenever it
exists.

| OS      | When the new theme shows                                         |
| ------- | ---------------------------------------------------------------- |
| macOS   | Right away: `helium-theme` reloads the extension via AppleScript |
| Linux   | At Helium's next start                                           |
| Windows | At Helium's next start                                           |

Only macOS can reload live: the reload runs JavaScript on `helium://extensions`,
and only AppleScript can reach that page from outside. On macOS,
`helium-theme` uses an open extensions tab when it finds one, so keeping one
open avoids the brief focus change of its hidden-window fallback.

## One-time setup per machine

Until the folder exists, theme switches skip Helium.

- **macOS and Linux:** run `helium-theme setup` and follow its steps.
- **Windows:** create the folder and copy in the current theme, then load it:

  ```powershell
  $dir = Join-Path $HOME ".local\state\helium-theme"   # or $env:XDG_STATE_HOME\helium-theme
  New-Item -ItemType Directory -Force $dir
  Copy-Item "$env:XDG_CONFIG_HOME\theme\helium\manifest.json" $dir
  ```

  In Helium, open `helium://extensions`, turn on Developer mode, choose Load
  unpacked, and pick that folder.

## Rules that matter when changing this

- Don't set the `BrowserThemeColor` policy. It overrides theme extensions.
- On macOS, the reload disables the theme, reloads it, then enables it again
  in a `finally`. Reloading the active theme makes Chromium fall back to the
  default theme. A theme left disabled gets uninstalled later.
