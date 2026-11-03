##=========================================
## ~/.config/shell/completions.zsh
##=========================================
# Puts completions for mise-installed tools on fpath. mise keeps each tool's
# files under its install directory, and some tools only print theirs, so
# collect them as `_name` files in one cache directory. Rebuild it daily so
# upgrades and removals don't leave stale entries.

_zsh_completion_cache="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/completions"

# Tools that print their completion function instead of shipping a file.
typeset -gA _zsh_generated_completions=(
  _bun 'bun completions'
  _cargo 'rustup completions zsh cargo'
  _gh 'gh completion -s zsh'
  _omp 'omp completions zsh'
  _pnpm 'pnpm completion zsh'
  _rustup 'rustup completions zsh rustup'
  _starship 'starship completions zsh'
  _uv 'uv generate-shell-completion zsh'
  _uvx 'uvx --generate-shell-completion zsh'
  _zellij 'zellij setup --generate-completion zsh'
)

# Keep a file only if it starts with a #compdef line, the form compinit loads.
_zsh_is_compdef_file() {
  local line
  read -r line <"$1" 2>/dev/null && [[ $line == '#compdef '* ]]
}

_zsh_build_completion_cache() {
  local dir=$_zsh_completion_cache tmp file name cmd
  tmp=$(mktemp -d "$dir.XXXXXX") || return

  # Shipped files are named `_name` or `name.zsh`; copy rather than link, since
  # mise deletes old versions on upgrade.
  for file in "${XDG_DATA_HOME:-$HOME/.local/share}"/mise/installs/*/latest/{,*/}{autocomplete,complete,completions}/{_*,*.zsh}(N-.); do
    _zsh_is_compdef_file "$file" || continue
    name=${file:t:r}
    [[ $name == _* ]] || name=_$name
    cp "$file" "$tmp/$name"
  done

  for name cmd in "${(@kv)_zsh_generated_completions}"; do
    (($+commands[${cmd%% *}])) || continue
    ${(z)cmd} >"$tmp/$name" 2>/dev/null </dev/null
    _zsh_is_compdef_file "$tmp/$name" || rm -f "$tmp/$name"
  done

  print -r -- "$_zsh_completion_generators" >"$tmp/.generators"
  rm -rf "$dir" && mv "$tmp" "$dir"
}

# The directory's mtime is when it was built; .generators records the list
# above it was built from, so a changed list rebuilds it too. Shells starting
# together (restored tabs) would race on the swap, so only the one holding the
# lock rebuilds.
_zsh_completion_generators=
for _zsh_name in ${(ok)_zsh_generated_completions}; do
  _zsh_completion_generators+="$_zsh_name=${_zsh_generated_completions[$_zsh_name]};"
done
unset _zsh_name
() {
  local dir=$_zsh_completion_cache lock fd
  local -a fresh=($dir(N/mh-24))
  ((${#fresh})) && [[ -r $dir/.generators && $(<$dir/.generators) == "$_zsh_completion_generators" ]] && return

  lock="$dir.lock"
  mkdir -p "${dir:h}" && : >>"$lock" || return
  zmodload -F zsh/system b:zsystem || return
  zsystem flock -t 0 -f fd "$lock" 2>/dev/null || return
  _zsh_build_completion_cache
  zsystem flock -u "$fd"
}
fpath=("$_zsh_completion_cache" "${fpath[@]}")
