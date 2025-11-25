{ lib, ... }:
{
  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = lib.mkDefault true;
    settings = {
      X11Forwarding = lib.mkDefault true;
    };
  };
}
