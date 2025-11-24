{ lib, ... }:
{
  programs.uv = {
    enable = lib.mkDefault true;
  };
}
