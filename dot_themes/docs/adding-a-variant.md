# Adding a theme variant

A variant is a folder `dot_themes/<variant>/` (deployed to `~/.themes/`) plus
entries in four shared files. `themes.test.ts` checks every piece below; the
variant is done when `pnpm test` is green and `pnpm check-nvim <variant>`
applies its colorscheme with no error.

Name variants in kebab case. A family's dark variant usually takes the family
name (`horizon`, light `horizon-bright`); see `CONTEXT.md` for families and
modes.

## 1. Per-app files: the generator

1. Seed a roles file from Ghostty's bundled theme when one exists (catalog:
   `/Applications/Ghostty.app/Contents/Resources/ghostty/themes/`):
   `pnpm new-variant seed <variant> --ghostty "<Name>" [--family <family>]`.
   Without a Ghostty theme, seed a template and fill the terminal colors from
   the theme's upstream terminal or VS Code colors.
2. Tune `dot_themes/tools/roles/<variant>.json` against the real theme
   (upstream Neovim plugin palette, VS Code theme): seeded semantic roles are
   blends and guesses. In light variants, darken `muted`, `dim` and `comment`
   until they read on the background.
3. When an upstream port exists (bat `.tmTheme`, yazi flavor), drop it in and
   pin it to a commit with a source comment, as `dawnfox/bat.tmTheme` does.
4. `pnpm new-variant generate <variant>` writes every missing per-app file,
   the yazi flavor link and the Windows Terminal scheme and theme. It skips
   files that exist, so upstream files from step 3 survive; `--force`
   regenerates.

## 2. Shared files the generator leaves to you

- **Neovim**, `dot_config/nvim/lua/plugins/colorscheme.lua`: a `theme_specs`
  entry for a new plugin, or an alias line when the plugin is already used
  (one entry per repo; the test enforces it). Read the plugin's source for its
  setup API, colorscheme names and transparency option. Then run
  `pnpm check-nvim <variant>...`: it loads each variant in a sandboxed
  headless Neovim and fails when the colorscheme does not apply (LazyVim
  silently falls back to `habamax`).
- **hunk**, `dot_config/shell/interactive.sh`: a `case` line mapping the
  variant to the closest name in `dot_themes/tools/hunk-themes.txt`, unless
  the variant's own name is in that list. Refresh the list after upgrading
  hunk with `pnpm hunk-themes`.
- **Wallpaper**, `.chezmoiexternal.toml.tmpl`: an entry
  `[".themes/<variant>/backgrounds/background-1.jpg"]` and its credit line in
  the header list. Pick a Pexels photo matching the variant's mode and mood,
  unused elsewhere in the file; look at it before choosing (fetch
  `https://images.pexels.com/photos/<id>/pexels-photo-<id>.jpeg?w=640` and
  read the image).

## Several variants at once

Give each parallel agent its own variants and have it write the shared-file
pieces as snippets in a scratch folder; merge them in one pass, since
concurrent edits to the shared files collide. Commit one variant or family
per commit, as the history does.
