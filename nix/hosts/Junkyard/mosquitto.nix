{ config, ... }:
{
  sops = {
    secrets = {
      "mosquitto/root-password" = {
        sopsFile = ../../secrets/Junkyard/mosquitto.yaml;
        format = "yaml";
        owner = "mosquitto";
        group = "mosquitto";
      };
      "mosquitto/cert" = {
        sopsFile = ../../secrets/Junkyard/mosquitto.yaml;
        format = "yaml";
        owner = "mosquitto";
        group = "mosquitto";
      };
      "mosquitto/key" = {
        sopsFile = ../../secrets/Junkyard/mosquitto.yaml;
        format = "yaml";
        owner = "mosquitto";
        group = "mosquitto";
      };
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
          certfile = config.sops.secrets."mosquitto/cert".path;
          keyfile = config.sops.secrets."mosquitto/key".path;
          require_certificate = false;
        };
      }
    ];
  };

  networking.firewall.allowedTCPPorts = [
    1883
    8883
  ];
}
