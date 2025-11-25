{ lib, ... }:
{
  services.xserver = {
    enable = lib.mkDefault true;
  };

  services.displayManager.gdm = {
    enable = lib.mkDefault true;
    wayland = lib.mkDefault true;
  };

  programs = {
    xwayland.enable = lib.mkDefault true;
    hyprland.enable = lib.mkDefault true;
  };
}
