{ config, ... }:
{
  sops = {
    secrets = {
      "mosquitto/root-password" = {
        sopsFile = ../../secrets/Junkyard/mosquitto.yaml;
        format = "yaml";
        owner = "mosquitto";
        group = "mosquitto";
        restartUnits = [ "mosquitto.service" ];
      };
    };
  };

  security.acme.certs = {
    "junkyard.ianpascoe.dev" = {
      dnsProvider = "cloudflare";
      environmentFile = config.sops.secrets."cloudflare/env".path;
      group = "mosquitto";
      reloadServices = [ "mosquitto.service" ];
    };
  };

  services.mosquitto = {
    enable = true;
    listeners = [
      {
        users.root = {
          acl = [
            "readwrite #"
          ];
          passwordFile = config.sops.secrets."mosquitto/root-password".path;
        };
        port = 1883;
      }
    ];
  };

  networking.firewall.allowedTCPPorts = [
    1883
  ];
}
