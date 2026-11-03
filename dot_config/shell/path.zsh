##=========================================
## ~/.config/shell/path.zsh
##=========================================

typeset -gU path PATH

_zsh_prepend_path_existing() {
  local dir
  local -a dirs

  for dir in "$@"; do
    [[ -d "$dir" ]] || continue
    path=(${path:#$dir})
    dirs+=("$dir")
  done

  ((${#dirs[@]} == 0)) && return
  path=("${dirs[@]}" "${path[@]}")
}

_zsh_apply_base_path_order() {
  # Only Linux has Linuxbrew. On macOS any lookup under /home wakes the
  # automounter, ~18ms each, and this runs several times per shell.
  local -a linuxbrew
  case "$OSTYPE" in
  linux*) linuxbrew=(/home/linuxbrew/.linuxbrew/bin /home/linuxbrew/.linuxbrew/sbin) ;;
  esac

  _zsh_prepend_path_existing \
    "$HOME/.local/bin" \
    "${XDG_DATA_HOME:-$HOME/.local/share}/mise/shims" \
    "${XDG_CACHE_HOME:-$HOME/.cache}/.bun/bin" \
    "$HOME/.local/share/pnpm/bin" \
    "$HOME/.npm-global/bin" \
    "$HOME/.cargo/bin" \
    /opt/homebrew/opt/curl/bin \
    /opt/homebrew/bin \
    /opt/homebrew/sbin \
    "${linuxbrew[@]}"
}
