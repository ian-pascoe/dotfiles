{ lib, ... }:
{
  services.displayManager.sddm = lib.mkDefault {
    enable = true;
    wayland.enable = true;
  };
}
