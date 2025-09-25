{
  config,
  dotfiles,
  ...
}: {
  imports = [
    ../../../../../../util/home/dotfiles
  ];
  programs.ghostty = {
    enable = true;
  };
  xdg.configFile.ghostty = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfiles.path}/.config/ghostty";
    force = true;
  };
}
