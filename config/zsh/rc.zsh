##============================
## .zshrc
##============================

## History
HISTSIZE=10000
SAVEHIST=$HISTSIZE
HISTFILE="$HOME/.zsh_history"

# Persist history immediately and dedupe entries
setopt appendhistory
setopt inc_append_history
setopt hist_ignore_dups
setopt hist_ignore_all_dups
setopt hist_save_no_dups

## ZPlug
export ZPLUG_HOME="$(brew --prefix zplug)"
if [ -d "${ZPLUG_HOME}" ]; then
  source "${ZPLUG_HOME}/init.zsh"

  zplug "zsh-users/zsh-autosuggestions"
  zplug "zsh-users/zsh-syntax-highlighting", defer:2

  if ! zplug check --verbose; then
    printf "Install? [y/N]: "
    if read -rq; then
      echo
      zplug install
    fi
  fi
  zplug load
fi

## Mise
if command -v mise &>/dev/null; then
  eval "$(mise activate zsh)"
fi

## Editor
if command -v nvim &>/dev/null; then
  export EDITOR='nvim'
  alias vim='nvim'
else
  export EDITOR='vim'
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

## Cargo
if [ -f "$HOME/.cargo/env" ]; then
  source "$HOME/.cargo/env"
fi

## FZF
if command -v fzf &>/dev/null; then
  source <(fzf --zsh)
fi

## Zellij
if command -v zellij &>/dev/null; then
  alias zj='zellij'
  alias zjd='zellij --layout dev'
  alias zjk='zellij kill-sessions'
  alias zjka='zellij kill-all-sessions'
fi

# Environment-Specific Env
if [ -f "$HOME/.env.sh" ]; then
  source "$HOME/.env.sh"
fi

# Secrets
if [ -f "$HOME/.secrets.sh" ]; then
  source "$HOME/.secrets.sh"
fi

# OpenClaw
if command -v openclaw &>/dev/null; then
  source "$HOME/.openclaw/completions/openclaw.zsh"
fi

# Brewfile
if command -v brew &>/dev/null; then
  brew() {
    command brew "$@"
    if [[ "$1" =~ ^(install|uninstall|remove|upgrade)$ ]]; then
      command brew bundle dump --force --file=~/Brewfile
    fi
  }
fi

## Zoxide
if command -v zoxide &>/dev/null; then
  eval "$(zoxide init zsh)"
  function zd() {
    if [ $# -eq 0 ]; then
      builtin cd ~ && zoxide add "$(pwd)" && return
    elif [ -d "$1" ]; then
      builtin cd "$1" && zoxide add "$(pwd)" && return
    else
      z "$@" && printf "\U000F17A9 " && pwd || echo "Error: Directory not found"
    fi
  }
  alias cd='zd'
fi

## Starship
if command -v starship &>/dev/null; then
  # clear stale readline state before rendering prompt (prevents artifacts in prompt after abnormal exits like SIGQUIT)
  __sanitize_prompt() { printf '\r\033[K'; }
  PROMPT_COMMAND="__sanitize_prompt${PROMPT_COMMAND:+;$PROMPT_COMMAND}"
  eval "$(starship init zsh)"
fi
