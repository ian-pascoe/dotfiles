##===================================
## .zshenv
##===================================

## XDG Directories
export XDG_CONFIG_HOME=$HOME/.config
export XDG_DATA_HOME=$HOME/.local/share
export XDG_STATE_HOME=$HOME/.local/state
export XDG_CACHE_HOME=$HOME/.cache

## Global Bun packages
export PATH=$XDG_CACHE_HOME/.bun/bin:$PATH

## Local bin
export PATH=$HOME/.local/bin:$PATH
