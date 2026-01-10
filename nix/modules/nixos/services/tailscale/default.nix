{ lib, ... }:
{
  services.tailscale = {
    enable = lib.mkDefault true;
  };
}
