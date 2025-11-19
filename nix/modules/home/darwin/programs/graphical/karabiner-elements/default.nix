{
  config,
  dotfiles,
  ...
}:
{
  # Install handled via homebrew
  xdg.configFile.karabiner = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfiles.path}/config/karabiner";
    force = true;
  };
}
