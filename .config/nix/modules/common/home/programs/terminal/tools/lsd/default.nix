{
  config,
  dotfiles,
  ...
}:
{
  imports = [
    ../../../../../../util/home/dotfiles
  ];
  programs.lsd = {
    enable = true;
  };
  xdg.configFile.lsd = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfiles.path}/.config/lsd";
    force = true;
  };
}
