{
  config,
  lib,
  dotfiles,
  ...
}:
{
  programs.starship = {
    enable = lib.mkDefault true;
  };

  xdg.configFile = {
    "starship.toml" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfiles.path}/config/starship.toml";
      force = true;
    };
  };
}
