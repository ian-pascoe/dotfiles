{
  config,
  dotfiles,
  ...
}:
{
  imports = [
    ../../../../../../util/home/dotfiles
  ];

  programs.opencode = {
    enable = true;
  };

  xdg.configFile.opencode = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfiles.path}/config/opencode";
    force = true;
  };
}
