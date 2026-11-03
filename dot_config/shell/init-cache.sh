##=========================================
## ~/.config/shell/init-cache.sh
##=========================================
# Caches the init scripts tools print for `eval "$(tool init)"`, so a shell
# start reads a file instead of running each tool. Valid in bash and zsh.
#
#   _shell_init_cache NAME COMMAND [ARG...] && . "$_shell_init_file"
#
# Source the file at the top level, not from inside a function: init scripts
# declare globals with typeset, which a function would make local.
#
# The cache is rebuilt when it is a day old, when COMMAND's program is newer
# than it, or when the command line changes. Returns 1 when COMMAND isn't
# installed or prints nothing; then there is nothing to source.

_shell_init_cache() {
  local name=$1 bin now header stamp out
  shift
  _shell_init_file="${XDG_CACHE_HOME:-$HOME/.cache}/shell/init/$name"

  if [ -n "${ZSH_VERSION:-}" ]; then
    case $1 in
    /*) bin=$1 ;;
    *) bin=${commands[$1]-} ;;
    esac
    zmodload -F zsh/datetime p:EPOCHSECONDS 2>/dev/null
  else
    bin=$(type -P "$1")
  fi
  [ -n "$bin" ] && [ -x "$bin" ] || return 1
  now=${EPOCHSECONDS:-$(date +%s)}

  # The first line is "# <epoch> <command line>".
  if [ -f "$_shell_init_file" ] && ! [ "$bin" -nt "$_shell_init_file" ] &&
    IFS= read -r header <"$_shell_init_file"; then
    stamp=${header#\# }
    stamp=${stamp%% *}
    case $stamp in
    '' | *[!0-9]*) stamp=0 ;;
    esac
    if [ "$header" = "# $stamp $*" ] && [ $((now - stamp)) -lt 86400 ]; then
      return 0
    fi
  fi

  out=$("$@" 2>/dev/null </dev/null)
  [ -n "$out" ] || return 1
  if mkdir -p "${_shell_init_file%/*}" 2>/dev/null &&
    printf '# %s %s\n%s\n' "$now" "$*" "$out" 2>/dev/null >"$_shell_init_file.$$" &&
    mv -f "$_shell_init_file.$$" "$_shell_init_file"; then
    return 0
  fi
  # The cache can't be written: hand over a file this shell owns instead.
  rm -f "$_shell_init_file.$$"
  _shell_init_file="${TMPDIR:-/tmp}/shell-init.$$.$name"
  printf '%s\n' "$out" >"$_shell_init_file"
}
