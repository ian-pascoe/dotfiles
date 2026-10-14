##=========================================
## ~/.config/shell/egress-proxy.sh
##=========================================

# Sends HTTP(S) traffic from this shell's programs through an egress proxy
# (the home router, over Tailscale) and keeps tailnet, LAN and infrastructure
# hosts direct. Opt in per machine in ~/.env, which login.sh sources first:
#
#   export EGRESS_PROXY_HTTP='http://100.68.1.66:1056'
#   export EGRESS_PROXY_SOCKS='socks5h://100.68.1.66:1055' # optional: ALL_PROXY
#   export EGRESS_NO_PROXY_EXTRA='example.com,.example.org' # optional
#
# NO_PROXY is built when this file is sourced: fixed entries plus every
# tailnet peer's MagicDNS name and addresses. Node's fetch ignores CIDR
# entries, hence the per-peer addresses. Source this file again to pick up
# new peers.

_egress_no_proxy() {
  {
    printf '%s\n' localhost 127.0.0.1 ::1 169.254.169.254 \
      .ts.net 100.64.0.0/10 fd7a:115c:a1e0::/48 192.168.50.0/24
    if [ -n "${EGRESS_NO_PROXY_EXTRA:-}" ]; then
      printf '%s\n' "$EGRESS_NO_PROXY_EXTRA" | tr ',' '\n'
    fi
    if command -v jq >/dev/null 2>&1 && command -v tailscale >/dev/null 2>&1; then
      tailscale status --json 2>/dev/null | jq -r '
        ([.Self] + [.Peer[]?])[]
        | (.DNSName // "" | rtrimstr(".") | split(".")[0]), .TailscaleIPs[]?'
    fi
  } | grep -v '^$' | sort -u | paste -sd, -
}

# Succeeds unless Tailscale reports the proxy's peer as offline, so a down
# router means direct traffic rather than every request failing.
_egress_proxy_reachable() {
  _egress_host=${EGRESS_PROXY_HTTP#*://}
  _egress_host=${_egress_host%%[:/]*}
  command -v tailscale >/dev/null 2>&1 && command -v jq >/dev/null 2>&1 || return 0
  [ "$(tailscale status --json 2>/dev/null | jq -r --arg ip "$_egress_host" '
    [.Peer[]? | select((.TailscaleIPs // []) | index($ip)) | .Online][0]
    | if . == null then true else . end
  ')" != false ]
}

if [ -n "${EGRESS_PROXY_HTTP:-}" ]; then
  if _egress_proxy_reachable; then
    export HTTP_PROXY="$EGRESS_PROXY_HTTP" HTTPS_PROXY="$EGRESS_PROXY_HTTP"
    export http_proxy="$EGRESS_PROXY_HTTP" https_proxy="$EGRESS_PROXY_HTTP"
    NO_PROXY=$(_egress_no_proxy)
    export NO_PROXY no_proxy="$NO_PROXY"
    export NODE_USE_ENV_PROXY=1
    if [ -n "${EGRESS_PROXY_SOCKS:-}" ]; then
      export ALL_PROXY="$EGRESS_PROXY_SOCKS" all_proxy="$EGRESS_PROXY_SOCKS"
    else
      unset ALL_PROXY all_proxy
    fi
  else
    unset HTTP_PROXY HTTPS_PROXY http_proxy https_proxy ALL_PROXY all_proxy \
      NO_PROXY no_proxy NODE_USE_ENV_PROXY
    if [ -t 2 ]; then
      echo "egress-proxy: $EGRESS_PROXY_HTTP is offline in Tailscale; going direct" >&2
    fi
  fi
fi

unset -f _egress_no_proxy _egress_proxy_reachable
unset _egress_host
