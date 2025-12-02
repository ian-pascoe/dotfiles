{ config, ... }:
{
  sops = {
    secrets = {
      "mosquitto/root-password" = {
        sopsFile = ../../secrets/Junkyard/mosquitto.yaml;
        format = "yaml";
      };
      "mosquitto/cert" = {
        sopsFile = ../../secrets/Junkyard/mosquitto.yaml;
        format = "yaml";
      };
      "mosquitto/key" = {
        sopsFile = ../../secrets/Junkyard/mosquitto.yaml;
        format = "yaml";
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
        port = 1883;
        settings = {
          certfile = config.sops.secrets."mosquitto/cert".path;
          keyfile = config.sops.secrets."mosquitto/key".path;
        };
      }
    ];
  };

  networking.firewall.allowedTCPPorts = [ 1883 ];
}
