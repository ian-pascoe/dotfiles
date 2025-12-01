{ lib, ... }:
{
  services.openssh = {
    enable = lib.mkDefault true;
    extraConfig = ''
      PermitRootLogin no
      X11Forwarding yes
    '';
  };
}
