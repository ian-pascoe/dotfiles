#!/usr/bin/env bash
# Loads each named theme variant in a headless Neovim that runs this source
# tree's Neovim config in an isolated XDG sandbox, and reports the colorscheme it
# applied, 'background', Normal and Keyword colors, and any error. Exits non-zero
# if a variant fails to apply its colorscheme or reports an error.
#
#   check-nvim.sh <variant>...    (pnpm run check-nvim <variant>...)
#
# The first run installs every plugin into ~/.cache/theme-nvim-check (about a
# minute); later runs reuse it. The theme link and light.mode marker are faked
# inside the sandbox, so ~/.config/theme is untouched.
set -euo pipefail

if [[ $# -eq 0 ]]; then
  echo "Usage: $0 <variant>..." >&2
  exit 1
fi

source_dir=$(cd "$(dirname "$0")/../.." && pwd)
sandbox=${THEME_NVIM_CHECK_DIR:-$HOME/.cache/theme-nvim-check}
export XDG_CONFIG_HOME=$sandbox/config XDG_DATA_HOME=$sandbox/data
export XDG_STATE_HOME=$sandbox/state XDG_CACHE_HOME=$sandbox/cache
mkdir -p "$XDG_CONFIG_HOME" "$sandbox/themes"
rsync -a --delete --exclude node_modules "$source_dir/dot_config/nvim/" "$XDG_CONFIG_HOME/nvim/"

link_theme() {
  rm -rf "${sandbox:?}/themes/$1"
  mkdir -p "$sandbox/themes/$1"
  if [[ -f $source_dir/dot_themes/$1/empty_light.mode ]]; then
    touch "$sandbox/themes/$1/light.mode"
  fi
  ln -snf "$sandbox/themes/$1" "$XDG_CONFIG_HOME/theme"
}

# Prints one RESULT line once startup has settled (lazy-loaded plugins, the
# colorscheme and LazyVim's own setup).
report='lua vim.defer_fn(function()
  local function fg(group, key)
    local hl = vim.api.nvim_get_hl(0, { name = group, link = false })
    return hl[key] and string.format("#%06x", hl[key]) or "none"
  end
  io.stdout:write(string.format("\nRESULT colors=%s background=%s Normal.bg=%s Normal.fg=%s Keyword.fg=%s error=%s\n",
    vim.g.colors_name or "NONE", vim.o.background, fg("Normal", "bg"), fg("Normal", "fg"),
    fg("Keyword", "fg"), vim.v.errmsg ~= "" and vim.v.errmsg or "none"))
  vim.cmd("qa!")
end, 3000)'

for variant in "$@"; do
  [[ -d $source_dir/dot_themes/$variant ]] || {
    echo "unknown variant: $variant" >&2
    exit 1
  }
done

link_theme "$1"
if [[ ! -d $XDG_DATA_HOME/nvim/lazy ]]; then
  echo "Installing plugins into $sandbox..." >&2
  (cd /tmp && nvim --headless "+Lazy! sync" +qa >/dev/null 2>&1) || true
fi

failed=0
for variant in "$@"; do
  link_theme "$variant"
  result=$(cd /tmp && timeout 120 nvim --headless -c "$report" 2>&1 | grep '^RESULT ' || true)
  printf '%-22s %s\n' "$variant" "${result#RESULT }"
  if [[ -z $result || $result == *"colors=NONE"* || $result != *"error=none" ]]; then
    failed=1
  fi
done
exit "$failed"
