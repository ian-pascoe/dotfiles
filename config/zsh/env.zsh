##===================================
## .zshenv
##===================================

## XDG Directories
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"
export XDG_CACHE_HOME="$HOME/.cache"

## OpenCode
export OPENCODE_EXPERIMENTAL=false

## Editor
if command -v nvim &>/dev/null; then
  export EDITOR='nvim'
else
  export EDITOR='vim'
fi

## Crosspack
if [ -d "$HOME/.crosspack/bin" ]; then
  case ":$PATH:" in
  *":$HOME/.crosspack/bin:"*) ;;
  *) export PATH="$HOME/.crosspack/bin:$PATH" ;;
  esac
fi

## Node
if [ -d "$HOME/.npm-global/bin" ]; then
  case ":$PATH:" in
  *":$HOME/.npm-global/bin:"*) ;;
  *) export PATH="$HOME/.npm-global/bin:$PATH" ;;
  esac
fi

# PNPM
export PNPM_HOME="$HOME/.local/share/pnpm"
if [ -d "$PNPM_HOME" ]; then
  case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
  esac
fi

## Bun
if [ -d "$XDG_CACHE_HOME/.bun/bin" ]; then
  case ":$PATH:" in
  *":$XDG_CACHE_HOME/.bun/bin:"*) ;;
  *) export PATH="$XDG_CACHE_HOME/.bun/bin:$PATH" ;;
  esac
fi

## Local bin
if [ -d "$HOME/.local/bin" ]; then
  case ":$PATH:" in
  *":$HOME/.local/bin:"*) ;;
  *) export PATH="$HOME/.local/bin:$PATH" ;;
  esac
fi
. "$HOME/.cargo/env"
