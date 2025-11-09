{
  config,
  dotfiles,
  ...
}:
{
  imports = [
    ../../../../../../util/home/dotfiles
  ];

  programs.zellij = {
    enable = true;
  };

  xdg.configFile = {
    "zellij/config.kdl" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfiles.path}/config/zellij/config.kdl";
      force = true;
    };
  };
}
