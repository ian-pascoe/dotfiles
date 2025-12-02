{ config, ... }:
{
  sops = {
    secrets = {
      "cloudflared/cert.pem" = {
        sopsFile = ../../secrets/Junkyard/cloudflared.yaml;
        format = "yaml";
      };
      "cloudflared/junkyard-server.json" = {
        sopsFile = ../../secrets/Junkyard/cloudflared.yaml;
        format = "yaml";
      };
    };
  };

  services.cloudflared = {
    enable = true;
    certificateFile = config.sops.secrets."cloudflared/cert.pem".path;
    tunnels = {
      junkyard-server = {
        credentialsFile = config.sops.secrets."cloudflared/junkyard-server.json".path;
        default = "http_status:404";
        ingress = {
          # Run: `cloudflared tunnel route dns junkyard-server home-assistant.ianpascoe.dev`
          "home-assistant.ianpascoe.dev" = {
            service = "http://localhost:8123";
          };
          # Run: `cloudflared tunnel route dns junkyard-server junkyard-ssh.ianpascoe.dev`
          "junkyard-ssh.ianpascoe.dev" = {
            service = "ssh://localhost:22";
          };
          # Run: `cloudflared tunnel route dns junkyard-server mqtt.ianpascoe.dev`
          "mqtt.ianpascoe.dev" = {
            service = "http://localhost:8080";
          };
        };
      };
    };
  };
}
