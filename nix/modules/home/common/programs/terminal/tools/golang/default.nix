{ pkgs, ... }:
{
  home.packages = with pkgs; [
    go
    delve
    gopls
  ];
}
