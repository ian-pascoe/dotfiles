##=========================================
## ~/.config/shell/interactive.sh
##=========================================
# Shared interactive config for bash and zsh. Keep this file valid in both;
# use $_shell_name for tools that emit shell-specific init scripts.

if [ -n "${ZSH_VERSION:-}" ]; then
  _shell_name='zsh'
elif [ -n "${BASH_VERSION:-}" ]; then
  _shell_name='bash'
else
  return 0
fi

## Editor
if command -v nvim &>/dev/null; then
  alias vim='nvim'
fi

## LSD
if command -v lsd &>/dev/null; then
  alias ls='lsd'
fi
alias l='ls'
alias ll='ls -l'
alias lla='ls -lA'
alias la='ls -A'
alias lt='ls --tree'
alias ltla='ls -lA --tree'

## Bat
if command -v bat &>/dev/null; then
  alias cat='bat --style=plain --paging=never'
fi

## Yazi
if command -v yazi &>/dev/null; then
  alias y='yazi'
fi

## Lazygit
if command -v lazygit &>/dev/null; then
  alias lg='lazygit'
fi

## Terraform
if command -v terraform &>/dev/null; then
  alias tf='terraform'
fi

## Brewfile
if command -v brew &>/dev/null; then
  brew() {
    command brew "$@"
    case "$1" in
    install | uninstall | remove | upgrade)
      command brew bundle dump --force --no-cargo --no-go --no-npm --no-uv --file="$HOME/Brewfile"
      ;;
    esac
  }
fi

## Hunk
if command -v hunk &>/dev/null; then
  hunk() {
    if [[ "$1" == "diff" ]]; then
      shift
      command hunk diff \
        --watch \
        --transparent-bg \
        --mode stack \
        --wrap \
        --theme "$(
          case "$(basename "$(readlink ~/.config/theme)")" in
          catppuccin) echo catppuccin-mocha ;;
          gruvbox) echo gruvbox-dark-medium ;;
          kanagawa) echo kanagawa-wave ;;
          everforest) echo everforest-dark ;;
          dracula) echo dracula ;;
          solarized) echo solarized-dark ;;
          one-dark) echo one-dark-pro ;;
          vesper) echo vesper ;;
          flexoki) echo github-dark-default ;;
          cyberdream) echo github-dark-high-contrast ;;
          carbonfox) echo github-dark-default ;;
          vague) echo min-dark ;;
          moonfly) echo vitesse-black ;;
          monokai-pro) echo monokai ;;
          oxocarbon) echo github-dark-default ;;
          melange) echo vitesse-dark ;;
          matte-black) echo vitesse-black ;;
          osaka-jade) echo everforest-dark ;;
          eldritch) echo synthwave-84 ;;
          black-metal) echo vitesse-black ;;
          modus-operandi) echo github-light-high-contrast ;;
          modus-vivendi) echo github-dark-high-contrast ;;
          zenbones-light) echo github-light ;;
          miasma) echo gruvbox-dark-soft ;;
          iceberg) echo github-dark-dimmed ;;
          mellow) echo vitesse-black ;;
          kanso) echo kanagawa-dragon ;;
          nightfly) echo material-theme-ocean ;;
          duskfox) echo rose-pine-moon ;;
          terafox) echo poimandres ;;
          ristretto) echo monokai ;;
          gruvbox-material) echo gruvbox-dark-medium ;;
          sonokai) echo monokai ;;
          nordic) echo nord ;;
          solarized-osaka) echo solarized-dark ;;
          tokyodark) echo tokyo-night ;;
          jellybeans) echo gruvbox-dark-hard ;;
          bluloco) echo github-dark-dimmed ;;
          embark) echo dracula ;;
          no-clown-fiesta) echo vesper ;;
          kanagawa-paper) echo kanagawa-dragon ;;
          boo) echo red ;;
          retro-82) echo night-owl ;;
          ethereal) echo tokyo-night ;;
          hackerman) echo vitesse-black ;;
          lumon) echo github-dark-dimmed ;;
          *) basename "$(readlink ~/.config/theme)" ;;
          esac
        )" \
        "$@"
    else
      command hunk "$@"
    fi
  }
fi

## Completions
if command -v omp &>/dev/null; then
  eval "$(omp completions "$_shell_name")"
fi

if command -v hermes &>/dev/null; then
  eval "$(hermes completion "$_shell_name")"
fi

# set-theme and set-theme-all take a theme family from list-themes, then a mode;
# set-theme-all also takes -n/--dry-run before them, random-theme-all takes only
# that, and set-mode takes a mode or toggle.
if command -v set-theme &>/dev/null; then
  if [ "$_shell_name" = zsh ]; then
    # _arguments runs $(list-themes) itself when completing.
    # shellcheck disable=SC2016
    _set_theme() {
      _arguments '1:family:($(list-themes))' '2:mode:(light dark)'
    }
    # shellcheck disable=SC2016
    _set_theme_all() {
      _arguments '(-n --dry-run)'{-n,--dry-run}'[check each machine without changing it]' \
        '1:family:($(list-themes))' '2:mode:(light dark)'
    }
    _random_theme_all() {
      _arguments '(-n --dry-run)'{-n,--dry-run}'[check each machine without changing it]'
    }
    _set_mode() {
      _arguments '1:mode:(light dark toggle)'
    }
    compdef _set_theme set-theme
    compdef _set_theme_all set-theme-all
    compdef _random_theme_all random-theme-all
    compdef _set_mode set-mode
  else
    _set_theme() {
      local cur=${COMP_WORDS[COMP_CWORD]} i position=0
      if [[ $cur == -* && ${COMP_WORDS[0]} == set-theme-all ]]; then
        mapfile -t COMPREPLY < <(compgen -W '-n --dry-run' -- "$cur")
        return
      fi
      # Complete the family, then the mode, counting only words after any options.
      for ((i = 1; i < COMP_CWORD; i++)); do
        [[ ${COMP_WORDS[i]} == -* ]] || ((position++))
      done
      case $position in
      0) mapfile -t COMPREPLY < <(compgen -W "$(list-themes)" -- "$cur") ;;
      1) mapfile -t COMPREPLY < <(compgen -W 'light dark' -- "$cur") ;;
      esac
    }
    _set_mode() {
      [[ $COMP_CWORD -eq 1 ]] || return
      mapfile -t COMPREPLY < <(compgen -W 'light dark toggle' -- "${COMP_WORDS[COMP_CWORD]}")
    }
    complete -F _set_theme set-theme set-theme-all
    complete -F _set_mode set-mode
    complete -W '-n --dry-run' random-theme-all
  fi
fi

## FZF
if command -v fzf &>/dev/null; then
  eval "$(fzf --"$_shell_name")"
fi

## Zoxide
if command -v zoxide &>/dev/null; then
  eval "$(zoxide init "$_shell_name")"
  zd() {
    if [ $# -eq 0 ]; then
      builtin cd ~ && zoxide add "$(pwd)" && return
    elif [ -d "$1" ]; then
      builtin cd "$1" && zoxide add "$(pwd)" && return
    else
      z "$@" && printf '\U000F17A9 ' && pwd || echo "Error: Directory not found"
    fi
  }
  alias cd='zd'
fi

unset _shell_name
