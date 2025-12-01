{ lib, ... }:
{
  services.openssh = {
    enable = lib.mkDefault true;
    extraConfig = ''
      AllowSFTP yes
      PermitRootLogin no
      X11Forwarding yes
    '';
  };
}
