{
  config,
  dotfiles,
  ...
}:
{
  programs.spotify-player = {
    enable = true;
  };

  xdg.configFile."spotify-player" = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfiles.path}/config/spotify-player";
    force = true;
  };
}
