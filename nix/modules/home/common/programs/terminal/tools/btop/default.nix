{
  config,
  lib,
  dotfiles,
  ...
}:
{
  programs.btop = {
    enable = lib.mkDefault true;
  };

  xdg.configFile = {
    btop = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfiles.path}/config/btop";
      force = true;
    };
  };

  home.shellAliases = {
    top = "btop";
  };
}
