{
  programs.sketchybar = {
    enable = true;
    configType = "lua";
    service.enable = true;
  };
  xdg.configFile.sketchybar = {
    source = ./config;
    recursive = true;
  };
}
