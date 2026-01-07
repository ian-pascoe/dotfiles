{ pkgs, ... }:
{
  home.packages = with pkgs; [
    cctools
    blueutil
  ];
}
