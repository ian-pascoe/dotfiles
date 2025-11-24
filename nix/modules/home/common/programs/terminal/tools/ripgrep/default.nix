{ lib, ... }:
{
  programs.ripgrep = {
    enable = lib.mkDefault true;
  };
  home.shellAliases = {
    grep = "rg";
  };
}
