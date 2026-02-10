##============================
## .zshrc
##============================

## History
HISTCONTROL="ignoredups:erasedups"
HISTSIZE="10000"
HISTFILESIZE="$HISTSIZE"
HISTFILE="$HOME/.zsh_history"
setopt appendhistory

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
alias ll='ls -l'
alias lla='ls -lA'

## Bat
if command -v bat &>/dev/null; then
  alias cat='bat --style=plain --paging=never'
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
