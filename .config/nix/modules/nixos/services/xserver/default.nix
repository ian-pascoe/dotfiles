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
    displayManager.lightdm.enable = true;
    desktopManager.xfce.enable = true;
  };
}
