{
  lib,
  config,
  pkgs,
  dotfiles,
  ...
}:
{
  imports = [
    ../../../../../../util/home/dotfiles
  ];

  programs.yazi = {
    enable = true;
    shellWrapperName = "y";
  };

  xdg.configFile.yazi = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfiles.path}/config/yazi";
    force = true;
  };

  home.activation = {
    setupYazi = lib.hm.dag.entryAfter [ "programs.yazi.enable" ] ''
      export PATH="${pkgs.git}/bin:$PATH"
      ${config.programs.yazi.package}/bin/ya pkg install
    '';
  };
}
