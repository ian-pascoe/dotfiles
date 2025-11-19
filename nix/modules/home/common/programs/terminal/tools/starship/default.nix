{
  config,
  dotfiles,
  ...
}:
{
  programs.starship = {
    enable = true;
  };

  xdg.configFile = {
    "starship.toml" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfiles.path}/config/starship.toml";
      force = true;
    };
  };
}
