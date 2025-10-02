{ pkgs, ... }:
{
  home.packages = with pkgs; [
    wl-clipboard
    wl-clipboard-x11
  ];
}
