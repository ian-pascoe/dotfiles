{ config, ... }:
{
  homebrew = {
    enable = true;
    brews = [
      "mas"
      "media-control"
      "nextdns"
      "opencode"
      "podman"
      "podman-compose"
    ];
    casks = [
      "aldente"
      "balenaetcher"
      "betterdisplay"
      "bitwarden"
      "figma"
      "ghostty"
      "google-chrome"
      "helium-browser"
      "hiddenbar"
      "karabiner-elements"
      "nextcloud"
      "opencode-desktop"
      "pearcleaner"
      "podman-desktop"
      "spotify"
      "xquartz"
      "zoom"
    ];
    greedyCasks = true;
    masApps = {
      Infuse = 1136220934;
      WireGuard = 1451685025;
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
