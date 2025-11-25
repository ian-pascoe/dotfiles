{ lib, ... }:
{
  services.xserver = {
    enable = lib.mkDefault true;
    displayManager = {
      startx.enable = lib.mkDefault false;
      gdm = {
        enable = lib.mkDefault true;
        wayland.enable = lib.mkDefault true;
      };
    };
    videoDrivers = [ "modesetting" ];
    xkb.layout = "us";
  };

  programs.xwayland.enable = lib.mkDefault true;
}
