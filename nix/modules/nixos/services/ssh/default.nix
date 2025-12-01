{ lib, ... }:
{
  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = lib.mkDefault true;
    allowSFTP = lib.mkDefault true;
    settings = {
      PermitRootLogin = lib.mkDefault "no";
      X11Forwarding = lib.mkDefault true;
    };
  };
}
