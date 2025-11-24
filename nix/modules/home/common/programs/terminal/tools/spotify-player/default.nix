{
  config,
  lib,
  dotfiles,
  ...
}:
{
  programs.spotify-player = {
    enable = lib.mkDefault true;
  };

  xdg.configFile."spotify-player" = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfiles.path}/config/spotify-player";
    force = true;
  };
}
