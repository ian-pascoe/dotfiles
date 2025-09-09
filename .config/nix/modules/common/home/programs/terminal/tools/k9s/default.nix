{
  programs.k9s = {
    enable = true;
  };
  xdg.configFile.k9s = {
    source = ./config;
    recursive = true;
    force = true;
  };
}
