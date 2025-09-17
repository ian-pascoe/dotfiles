{
  pkgs,
  lib,
  ...
}: {
  environment.systemPackages = with pkgs; [
    xorg.xeyes # for testing
  ];
  services.xserver = lib.mkDefault {
    enable = true;
    desktopManager.gnome.enable = true;
    displayManager.gdm.enable = true;
    windowManager.hypr.enable = true;
  };
}
