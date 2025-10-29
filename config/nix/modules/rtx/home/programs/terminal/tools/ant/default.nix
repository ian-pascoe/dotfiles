{ pkgs, ... }:
{
  home.packages = with pkgs; [
    ant
  ];
}
