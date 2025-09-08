{
  programs.aerospace = {
    enable = true;
    launchd.enable = true;
  };
  xdg.configFile.aerospace = {
    source = ./config;
    recursive = true;
  };
}
