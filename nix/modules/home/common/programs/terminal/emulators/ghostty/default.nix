{
  pkgs,
  config,
  lib,
  dotfiles,
  ...
}:
{
  programs.ghostty = {
    enable = lib.mkDefault pkgs.stdenv.isLinux; # mac install handled via homebrew
  };

  xdg.configFile.ghostty = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfiles.path}/config/ghostty";
    force = true;
  };
}
