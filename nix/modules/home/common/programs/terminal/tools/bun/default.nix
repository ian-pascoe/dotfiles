{ lib, ... }:
{
  programs.bun = {
    enable = lib.mkDefault true;
  };

  home.sessionPath = [
    "$HOME/.cache/.bun/bin"
  ];
}
