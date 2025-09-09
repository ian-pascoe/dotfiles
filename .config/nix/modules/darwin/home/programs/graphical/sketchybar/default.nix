{config, ...}: {
  programs.sketchybar = {
    enable = true;
    configType = "lua";
    config = {
      source = config.lib.file.mkOutOfStoreSymlink ./config;
      recursive = true;
    };
  };
  home.shellAliases = {
    restart-sketchybar = ''launchctl kickstart -k gui/"$(id -u)"/org.nix-community.home.sketchybar'';
  };
}
