{
  config,
  dotfiles,
  ...
}: {
  imports = [
    ../../../../../../util/home/dotfiles
  ];

  programs.yazi = {
    enable = true;
  };

  xdg.configFile.yazi = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfiles.path}/.config/yazi";
    force = true;
  };
}
