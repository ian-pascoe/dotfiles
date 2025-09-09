{
  config,
  dotfiles,
  ...
}: {
  imports = [
    ../../../../../../util/home/dotfiles
  ];
  # install handled by homebrew
  xdg.configFile.ghostty = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfiles.path}/.config/ghostty";
    force = true;
  };
}
