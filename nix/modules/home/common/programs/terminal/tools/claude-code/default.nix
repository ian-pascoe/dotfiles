{
  pkgs,
  config,
  lib,
  dotfiles,
  ...
}:
{
  programs.claude-code = {
    enable = lib.mkDefault pkgs.stdenv.isLinux; # handled via homebrew on mac
  };

  home.file = {
    ".claude" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfiles.path}/config/claude-code";
      force = true;
    };
  };
}
