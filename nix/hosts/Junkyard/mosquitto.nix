{ config, ... }:
{
  sops = {
    secrets = {
      "mosquitto/root_password" = {
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
          passwordFile = config.sops.secrets."mosquitto/root_password".path;
        };
        port = 8080;
        settings = {
          protocol = "websockets";
        };
      }
    ];
  };
}
