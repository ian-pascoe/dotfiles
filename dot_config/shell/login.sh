##=========================================
## ~/.config/shell/login.sh
##=========================================

if [ -n "${BASH_VERSION:-}" ]; then
  _shell_name='bash'
elif [ -n "${ZSH_VERSION:-}" ]; then
  _shell_name='zsh'
else
  _shell_name='sh'
fi

## Init Script Cache (_shell_init_cache)
if [ -f "$HOME/.config/shell/init-cache.sh" ]; then
  . "$HOME/.config/shell/init-cache.sh"
fi

## Homebrew/Linuxbrew
if [ -x /opt/homebrew/bin/brew ]; then
  _shell_init_cache "brew-shellenv.$_shell_name" /opt/homebrew/bin/brew shellenv "$_shell_name" &&
    . "$_shell_init_file"
elif [ -x /home/linuxbrew/.linuxbrew/bin/brew ]; then
  _shell_init_cache "brew-shellenv.$_shell_name" /home/linuxbrew/.linuxbrew/bin/brew shellenv "$_shell_name" &&
    . "$_shell_init_file"
fi

## Crosspack
if [ -x "$HOME/.crosspack/bin/crosspack" ]; then
  eval "$("$HOME/.crosspack/bin/crosspack" init-shell --shell "$_shell_name")"
fi

## Cargo
if [ -f "$HOME/.cargo/env" ]; then
  source "$HOME/.cargo/env"
fi

## Python Venv
# Set the venv up directly instead of sourcing bin/activate: activate first runs
# deactivate, which restores the PS1 and PATH it saved earlier, so re-sourcing
# the shell files would drop the starship prompt and later PATH changes.
if [ -f "$HOME/.venv/bin/activate" ]; then
  export VIRTUAL_ENV="$HOME/.venv"
  case ":$PATH:" in
  *":$VIRTUAL_ENV/bin:"*) ;;
  *) export PATH="$VIRTUAL_ENV/bin:$PATH" ;;
  esac
fi

## Mise
if command -v mise &>/dev/null; then
  eval "$(mise activate "$_shell_name")"
fi

## Tirith
_shell_init_cache "tirith.$_shell_name" tirith init --shell "$_shell_name" &&
  . "$_shell_init_file"

## Tailscale
# One `tailscale status` per login (~40ms each), shared with egress-proxy.sh.
if command -v tailscale &>/dev/null && command -v jq &>/dev/null; then
  _tailscale_status=$(tailscale status --json 2>/dev/null)
  TAILSCALE_DOMAIN=$(printf '%s' "$_tailscale_status" | jq -r '
    .Self.DNSName | sub("\\.$"; "") | split(".")[1:] | join(".")' 2>/dev/null)
  TAILSCALE_IP=$(printf '%s' "$_tailscale_status" | jq -r '
    [.Self.TailscaleIPs[]? | select(contains("."))][0] // empty' 2>/dev/null)
  export TAILSCALE_DOMAIN TAILSCALE_IP
fi

## Environment-Specific Env
if [ -f "$HOME/.env" ]; then
  source "$HOME/.env"
fi

## Egress Proxy (opt in via EGRESS_PROXY_HTTP in ~/.env)
if [ -f "$HOME/.config/shell/egress-proxy.sh" ]; then
  source "$HOME/.config/shell/egress-proxy.sh"
fi
unset _tailscale_status

## SSH terminal fallback
if [ -n "${SSH_CONNECTION:-}" ] && [ "${TERM:-}" = "xterm-ghostty" ]; then
  if ! infocmp xterm-ghostty >/dev/null 2>&1; then
    if infocmp ghostty >/dev/null 2>&1; then
      export TERM='ghostty'
    else
      export TERM='xterm-256color'
    fi
  fi
fi

## Apply Base Path Order
if [ -n "${BASH_VERSION:-}" ] && command -v _bash_apply_base_path_order &>/dev/null; then
  _bash_apply_base_path_order
fi

if [ -n "${ZSH_VERSION:-}" ] && command -v _zsh_apply_base_path_order &>/dev/null; then
  _zsh_apply_base_path_order
fi

unset _shell_name
