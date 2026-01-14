{ config, ... }:
{
  homebrew = {
    enable = true;
    brews = [
      "anomalyco/tap/opencode"
      {
        name = "cliproxyapi";
        start_service = true;
        restart_service = true;
      }
      "mas"
      "media-control"
      "nextdns"
      "oven-sh/bun/bun"
      "podman"
      "podman-compose"
      "steveyegge/beads/bd"
    ];
    casks = [
      "aldente"
      "balenaetcher"
      "betterdisplay"
      "claude-code"
      "figma"
      "ghostty"
      "google-chrome"
      "handy"
      "helium-browser"
      "hiddenbar"
      "karabiner-elements"
      "opencode-desktop"
      "pearcleaner"
      "podman-desktop"
      "spotify"
      "tailscale-app"
      "xquartz"
      "zoom"
    ];
    greedyCasks = true;
    masApps = {
      Infuse = 1136220934;
    };
    taps = builtins.attrNames config.nix-homebrew.taps;
    onActivation = {
      autoUpdate = true;
      cleanup = "zap";
      upgrade = true;
    };
  };

  environment.variables = {
    HOMEBREW_BAT = "1";
    HOMEBREW_NO_ANALYTICS = "1";
    HOMEBREW_NO_INSECURE_REDIRECT = "1";
  };
}
