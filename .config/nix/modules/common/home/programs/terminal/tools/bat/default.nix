{
  pkgs,
  config,
  dotfiles,
  ...
}:
{
  imports = [
    ../../../../../../util/home/dotfiles
  ];

  programs.bat = {
    enable = true;
    extraPackages = [
      pkgs.bat-extras.core
    ];
  };

  xdg.configFile.bat = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfiles.path}/.config/bat";
    force = true;
  };

  home.shellAliases = {
    cat = "bat --paging=never";
  };
}
