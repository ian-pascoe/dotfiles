# History configuration
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000

# History options
setopt HIST_FIND_NO_DUPS      # Don't show duplicates when searching
setopt HIST_IGNORE_ALL_DUPS   # Remove older duplicate entries from history
setopt HIST_IGNORE_SPACE      # Don't save commands that start with space
setopt HIST_SAVE_NO_DUPS      # Don't save duplicate entries
setopt SHARE_HISTORY          # Share history between all sessions
setopt APPEND_HISTORY         # Append to history file
setopt INC_APPEND_HISTORY     # Write to history file immediately

# Local binaries
LOCALBIN_PATH="$HOME/.local/bin"
if [ -d "$LOCALBIN_PATH" ]; then
  export PATH="$LOCALBIN_PATH:$PATH"
fi

# True Color
export COLORTERM='truecolor'

# Language Config
export LANG=en_US.UTF-8

# Default Editor
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='nvim'
fi

# Compilation flags
export ARCHFLAGS="-arch $(uname -m)"

# Homebrew
if [[ $OSTYPE == 'darwin'* ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Starship
eval "$(starship init zsh)"

# zsh-autosuggestions
ZSH_AUTOSUGGESTIONS_PATH="$HOME/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh"
if [[ -f "$ZSH_AUTOSUGGESTIONS_PATH" ]]; then
  source "$ZSH_AUTOSUGGESTIONS_PATH"
fi

# Cargo
if [[ -f "$HOME/.cargo/env" ]]; then
  . "$HOME/.cargo/env"
fi

# Golang
if [[ $OSTYPE == 'darwin'* ]]; then
  export GOPATH="/opt/homebrew/Cellar/go/1.25.0/"
else
  export GOPATH="$HOME/.go"
fi

# fnm
FNM_PATH="$HOME/.local/share/fnm"
if [ -d "$FNM_PATH" ]; then
  export PATH="$FNM_PATH:$PATH"
  eval "`fnm env`"
fi

# opencode
OPENCODE_PATH="$HOME/.opencode/bin"
if [ -d "$OPENCODE_PATH" ]; then
  export PATH=$OPENCODE_PATH:$PATH
fi

# Aliases
alias ls='lsd'
alias cat='bat --paging=never'

# Auto-start tmux with session reuse
if command -v tmux &> /dev/null && [ -n "$PS1" ] && [[ ! "$TERM" =~ screen ]] && [[ ! "$TERM" =~ tmux ]] && [ -z "$TMUX" ]; then
  tmux attach-session -t default || tmux new-session -s default
fi

