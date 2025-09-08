{
  programs.lsd = {
    enable = true;
  };
  xdg.configFile.lsd = {
    source = ./config;
    recursive = true;
  };
}
