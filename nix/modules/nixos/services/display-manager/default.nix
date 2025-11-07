{ lib, ... }:
{
  services.displayManager.sddm = {
    enable = lib.mkDefault true;
    wayland.enable = lib.mkDefault true;
  };
}
