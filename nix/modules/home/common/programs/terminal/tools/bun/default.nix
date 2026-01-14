{ pkgs, lib, ... }:
{
  programs.bun = {
    enable = lib.mkDefault pkgs.stdenv.isLinux; # handled by homebrew on darwin
  };

  home.sessionPath = lib.mkBefore [
    "$HOME/.cache/.bun/bin"
  ];
}
