{
  pkgs,
  lib,
  ...
}:
{
  environment.systemPackages = with pkgs; [
    xorg.xeyes # for testing
  ];
  services.xserver = {
    enable = lib.mkDefault true;
  };
}
