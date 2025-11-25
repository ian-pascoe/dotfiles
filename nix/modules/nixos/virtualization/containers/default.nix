{ lib, ... }:
{
  virtualisation.containers = {
    enable = lib.mkDefault true;
  };
}
