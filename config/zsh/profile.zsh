##===========================================
## .zprofile
##===========================================

## Cargo
if [ -f "$HOME/.cargo/env" ]; then
  source "$HOME/.cargo/env"
fi

## Homebrew/Linuxbrew
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv zsh)"
elif [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv zsh)"
fi

# Environment-Specific Env
if [ -f "$HOME/.env.sh" ]; then
  source "$HOME/.env.sh"
fi

# Secrets
if [ -f "$HOME/.secrets.sh" ]; then
  source "$HOME/.secrets.sh"
fi
