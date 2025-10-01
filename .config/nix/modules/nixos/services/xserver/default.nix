{
  pkgs,
  lib,
  ...
<<<<<<< HEAD
}:
{
=======
}: {
>>>>>>> ff94daf (Revert "fix proxy config")
  environment.systemPackages = with pkgs; [
    xorg.xeyes # for testing
  ];
  services.xserver = lib.mkDefault {
    enable = true;
  };
}
