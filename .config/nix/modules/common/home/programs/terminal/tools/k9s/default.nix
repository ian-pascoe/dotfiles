{
  programs.k9s = {
    enable = true;
  };
  xdg.configFile.k9s = {
    source = ./config;
    force = true;
  };
}
