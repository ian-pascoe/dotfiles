{ pkgs, ... }:
{
  home.packages = with pkgs; [
    python314
    black
    mypy
    isort
    pipx
  ];
}
