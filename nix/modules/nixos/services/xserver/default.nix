{ lib, ... }:
{
  services.xserver = {
    enable = lib.mkDefault false;
  };
}
