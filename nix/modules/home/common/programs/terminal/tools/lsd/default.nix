{
  config,
  lib,
  dotfiles,
  ...
}:
{
  programs.lsd = {
    enable = lib.mkDefault true;
  };

  xdg.configFile = {
    lsd = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfiles.path}/config/lsd";
      force = true;
    };
  };
}
