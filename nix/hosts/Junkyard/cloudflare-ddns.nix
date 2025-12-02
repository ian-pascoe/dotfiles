{ config, ... }:
{
  sops.secrets = {
    "cloudflare/env" = {
      sopsFile = ../../secrets/cloudflare.yaml;
      format = "yaml";
    };
  };

  virtualisation.oci-containers = {
    containers.cloudflareddns = {
      image = "favonia/cloudflare-ddns:latest";
      environmentFiles = [
        config.sops.secrets."cloudflare/env".path
      ];
      environment = {
        PROXIED = "false";
        DOMAINS = "junkyard.ianpascoe.dev";
      };
      extraOptions = [
        "--network=host"
      ];
    };
  };
}
