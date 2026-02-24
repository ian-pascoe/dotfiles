##===========================================
## .zprofile
##===========================================

## Homebrew/Linuxbrew
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv zsh)"
elif [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv zsh)"
fi

## PATH order: local, crosspack, homebrew, then everything else
_zsh_config_dir="${${(%):-%N}:A:h}"
if [ -f "$_zsh_config_dir/path-order.zsh" ]; then
  source "$_zsh_config_dir/path-order.zsh"
  __enforce_path_priority
  unset -f __enforce_path_priority
fi
unset _zsh_config_dir

## Cargo
if [ -f "$HOME/.cargo/env" ]; then
  source "$HOME/.cargo/env"
fi

# Environment-Specific Env
if [ -f "$HOME/.env.sh" ]; then
  source "$HOME/.env.sh"
fi

# Secrets
if [ -f "$HOME/.secrets.sh" ]; then
  source "$HOME/.secrets.sh"
fi
