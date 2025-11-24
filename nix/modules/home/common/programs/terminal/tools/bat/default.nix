{
  config,
  lib,
  dotfiles,
  ...
}:
{
  programs.bat = {
    enable = lib.mkDefault true;
  };

  xdg.configFile = {
    bat = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfiles.path}/config/bat";
      force = true;
    };
  };

  home.shellAliases = {
    cat = "bat --paging=never";
  };
}
