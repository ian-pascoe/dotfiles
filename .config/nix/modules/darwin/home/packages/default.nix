{ pkgs, ... }:
{
  home.packages = with pkgs; [
    blueutil
  ];
}
