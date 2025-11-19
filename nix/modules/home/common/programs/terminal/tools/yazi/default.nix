{
  lib,
  config,
  dotfiles,
  ...
}:
{
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
      export PATH="${config.home.path}/bin:$PATH"
      run ${config.programs.yazi.package}/bin/ya pkg install
    '';
  };
}
