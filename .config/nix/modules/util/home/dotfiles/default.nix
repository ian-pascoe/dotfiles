{
  pkgs,
  config,
  lib,
  ...
}: let
  dotfiles = "${config.home.homeDirectory}/.dotfiles";
  dotfilesRepo = "https://github.com/ian-pascoe/dotfiles.git";
in {
  home.activation = {
    "setupDotfiles" = lib.hm.dag.entryAfter ["writeBoundary"] ''
      echo "Setting up dotfiles"
      if [ -d "${dotfiles}/.git" ]; then
        (cd "${dotfiles}" && ${pkgs.git}/bin/git pull --ff-only)
      else
        ${pkgs.git}/bin/git clone "${dotfilesRepo}" "${dotfiles}"
      fi
    '';
  };
  xdg.configFile.nix = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/.config/nix";
    force = true;
  };
  _module.args.dotfiles = {
    path = dotfiles;
    repo = dotfilesRepo;
  };
}
