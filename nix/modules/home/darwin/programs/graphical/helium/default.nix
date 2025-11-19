{
  config,
  lib,
  dotfiles,
  ...
}:
{
  home.file = {
    ".local/bin/install-helium-widevine" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfiles.path}/bin/install-helium-widevine";
      force = true;
    };
  };

  home.activation = {
    setupHelium = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      export PATH="${config.home.path}/bin:${config.home.homeDirectory}/.local/bin:/usr/bin:/bin:$PATH"
      install-helium-widevine
    '';
  };
}
