{
  homebrew = {
    enable = true;
    brews = [
      "mas"
      "rofi"
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
    onActivation = {
      autoUpdate = true;
      cleanup = "zap";
      upgrade = true;
    };
  };
}
