{
  homebrew = {
    enable = true;
    brews = [
      "mas"
      "sst/tap/opencode"
    ];
    casks = [
      "ghostty@tip"
      "google-chrome"
      "karabiner-elements"
    ];
    masApps = {
      WireGuard = 1451685025;
    };
    taps = [
      "sst/tap"
    ];
    onActivation = {
      autoUpdate = true;
      cleanup = "zap";
      upgrade = true;
    };
  };
}
