{ lib, ... }:
{
  programs.fd = {
    enable = lib.mkDefault true;
  };
}
