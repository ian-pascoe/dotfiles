{
  pkgs,
  config,
  lib,
  dotfiles,
  ...
}:
{
  imports = [
    ../../../../../../util/home/dotfiles
  ];
  programs.ghostty = lib.mkDefault {
    enable = pkgs.stdenv.isLinux; # mac install handled via homebrew
  };
  xdg.configFile.ghostty = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfiles.path}/config/ghostty";
    force = true;
  };
}
