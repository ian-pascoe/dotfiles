{
  config,
  dotfiles,
  ...
}:
{
  imports = [
    ../../../../../../util/home/dotfiles
  ];
  programs.k9s = {
    enable = true;
  };
  xdg.configFile.k9s = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfiles.path}/.config/k9s";
    force = true;
  };
}
