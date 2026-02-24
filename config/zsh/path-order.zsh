##===================================
## Shared PATH ordering
##===================================

__enforce_path_priority() {
  typeset -a _path_priority _path_rest _path_ordered
  typeset -A _path_priority_lookup

  _path_priority=()
  [[ -d "$HOME/.local/bin" ]] && _path_priority+=("$HOME/.local/bin")
  [[ -d "$HOME/.crosspack/bin" ]] && _path_priority+=("$HOME/.crosspack/bin")

  if [[ -n "${HOMEBREW_PREFIX:-}" ]]; then
    [[ -d "$HOMEBREW_PREFIX/bin" ]] && _path_priority+=("$HOMEBREW_PREFIX/bin")
    [[ -d "$HOMEBREW_PREFIX/sbin" ]] && _path_priority+=("$HOMEBREW_PREFIX/sbin")
  fi

  for _path_dir in "${_path_priority[@]}"; do
    _path_priority_lookup["$_path_dir"]=1
  done

  _path_rest=()
  for _path_dir in "${path[@]}"; do
    [[ -n "${_path_priority_lookup["$_path_dir"]:-}" ]] && continue
    _path_rest+=("$_path_dir")
  done

  _path_ordered=("${_path_priority[@]}" "${_path_rest[@]}")
  typeset -U _path_ordered
  path=("${_path_ordered[@]}")
  export PATH
}
