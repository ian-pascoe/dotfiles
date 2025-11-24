{ lib, ... }:
{
  programs.obsidian = {
    enable = lib.mkDefault true;
  };
}
