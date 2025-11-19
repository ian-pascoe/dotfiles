{ config, ... }:
{
  homebrew = {
    enable = true;
    brews = [
      "mas"
      "media-control"
      "opencode"
      "nextdns"
      "wireguard-tools"
    ];
    casks = [
      "ghostty"
      "helium-browser"
      "google-chrome"
      "bitwarden"
      "spotify"
      "karabiner-elements"
      "betterdisplay"
      "pearcleaner"
      "hiddenbar"
      "aldente"
      "nextcloud"
      "figma"
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
