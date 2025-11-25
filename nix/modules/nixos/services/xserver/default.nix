{ lib, ... }:
{
  services.xserver = {
    enable = lib.mkDefault true;
    displayManager.startx.enable = lib.mkDefault false;
    videoDrivers = [ "modesetting" ];
    xkb.layout = "us";
  };

  program.xwayland.enable = lib.mkDefault true;
}
