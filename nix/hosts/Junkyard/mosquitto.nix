{ config, ... }:
{
  sops = {
    secrets = {
      "mosquitto/root-password" = {
        sopsFile = ../../secrets/Junkyard/mosquitto.yaml;
        format = "yaml";
        owner = "mosquitto";
        group = "mosquitto";
        reloadServices = [ "mosquitto.service" ];
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
        port = 8883;
        settings = {
          cafile = "/var/lib/acme/junkyard.ianpascoe.dev/chain.pem";
          certfile = "/var/lib/acme/junkyard.ianpascoe.dev/cert.pem";
          keyfile = "/var/lib/acme/junkyard.ianpascoe.dev/key.pem";
          require_certificate = false;
        };
      }
    ];
  };

  networking.firewall.allowedTCPPorts = [
    8883
  ];
}
