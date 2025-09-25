{
  homebrew = {
    enable = true;
    brews = [
      "mas"
    ];
    casks = [
      # "ghostty@tip"
      "google-chrome"
      "spotify"
      "betterdisplay"
    ];
    masApps = {
      WireGuard = 1451685025;
    };
    taps = [];
    onActivation = {
      autoUpdate = true;
      cleanup = "zap";
      upgrade = true;
    };
  };
}
