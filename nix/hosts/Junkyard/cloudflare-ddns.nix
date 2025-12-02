{ config, ... }:
{
  sops.secrets = {
    "cloudflare/api-token" = {
      sopsFile = ../../secrets/cloudflare.yaml;
      format = "yaml";
    };
  };

  virtualisation.oci-containers = {
    containers.cloudflareddns = {
      image = "favonia/cloudflare-ddns:latest";
      environment = {
        CLOUDFLARE_API_TOKEN = "$(cat ${config.sops.secrets."cloudflare/api-token".path})";
        PROXIED = "true";
        DOMAINS = "junkyard.ianpascoe.dev";
      };
      extraOptions = [
        "--network=host"
      ];
    };
  };
}
