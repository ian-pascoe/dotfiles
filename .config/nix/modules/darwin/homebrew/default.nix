{
  homebrew = {
    enable = true;
    brews = [
      "mas"
      "media-control"
    ];
    casks = [
      "ghostty@tip"
      "google-chrome"
      "spotify"
      "karabiner-elements"
      "betterdisplay"
    ];
    masApps = {
      WireGuard = 1451685025;
    };
    taps = [];
    greedyCasks = true;
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
