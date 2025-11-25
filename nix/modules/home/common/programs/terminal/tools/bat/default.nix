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
    "bat/config" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfiles.path}/config/bat/config";
      force = true;
    };
  };

  home.shellAliases = {
    cat = "bat --paging=never";
  };
}
