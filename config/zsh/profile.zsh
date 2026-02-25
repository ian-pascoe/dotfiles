##===========================================
## .zprofile
##===========================================

## Homebrew/Linuxbrew
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv zsh)"
elif [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv zsh)"
fi

## Crosspack
if [[ -x "$HOME/.crosspack/bin/crosspack" ]]; then
  source <("$HOME/.crosspack/bin/crosspack" init-shell --shell zsh)
fi

## Cargo
if [ -f "$HOME/.cargo/env" ]; then
  source "$HOME/.cargo/env"
fi

## Environment-Specific Env
if [ -f "$HOME/.env" ]; then
  source "$HOME/.env"
fi
