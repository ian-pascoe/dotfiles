{lib, ...}: {
  services.xserver = lib.mkDefault {
    enable = true;
    displayManager.lightdm.enable = true;
    desktopManager.xfce.enable = true;
  };
}
