{
  config,
  dotfiles,
  ...
}: {
  imports = [
    ../../../../../../util/home/dotfiles
  ];
  programs.btop = {
    enable = true;
  };
  xdg.configFile.btop = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfiles.path}/.config/btop";
    force = true;
  };
}
