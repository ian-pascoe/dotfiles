{
  homebrew = {
    enable = true;
    brews = [
      "mas"
    ];
    casks = [
      "ghostty@tip"
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
