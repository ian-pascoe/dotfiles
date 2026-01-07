{ config, lib, ... }:
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

  networking.firewall.allowedTCPPorts = if config.services.openssh.enable then [ 22 ] else [ ];
}
