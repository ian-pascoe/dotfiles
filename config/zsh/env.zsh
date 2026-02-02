##===================================
## .zshenv
##===================================

## XDG Directories
export XDG_CONFIG_HOME=$HOME/.config
export XDG_DATA_HOME=$HOME/.local/share
export XDG_STATE_HOME=$HOME/.local/state
export XDG_CACHE_HOME=$HOME/.cache

## Node
export PATH=$HOME/.npm-global/bin:$PATH

# PNPM
export PNPM_HOME="/Users/ianpascoe/.local/share/pnpm"
case ":$PATH:" in
*":$PNPM_HOME:"*) ;;
*) export PATH="$PNPM_HOME:$PATH" ;;
esac

## Bun
export PATH=$XDG_CACHE_HOME/.bun/bin:$PATH

## Local bin
export PATH=$HOME/.local/bin:$PATH
