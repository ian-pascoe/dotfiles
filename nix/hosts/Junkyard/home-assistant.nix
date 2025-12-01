{ pkgs, lib, ... }:
let
  hacs = pkgs.buildHomeAssistantComponent rec {
    owner = "hacs";
    domain = "hacs";
    version = "2.0.5";

    src = pkgs.fetchzip {
      url = "https://github.com/hacs/integration/releases/download/${version}/hacs.zip";
      hash = "sha256-iMomioxH7Iydy+bzJDbZxt6BX31UkCvqhXrxYFQV8Gw=";
      stripRoot = false;
    };

    dependencies = with pkgs.python3Packages; [
      aiogithubapi
    ];

    meta = rec {
      description = "Home Assistant Community Store";
      homepage = "https://github.com/hacs/integration";
      changelog = "${homepage}/releases/tag/${version}";
      license = lib.licenses.unlicense;
    };
  };
in
{
  services.home-assistant = {
    enable = true;
    extraPackages =
      pythonPackages: with pythonPackages; [
        gtts
        grpclib
        grpcio
        sharkiq
        ibeacon-ble
        bidict
      ];
    extraComponents = [
      "default_config"
      "met"
      "esphome"
      "roku"
      "sharkiq"
      "nest"
      "remote"
      "denon"
      "denonavr"
      "nmap_tracker"
    ];
    customComponents = with pkgs.home-assistant-custom-components; [
      hacs
      spook
    ];
    config = {
      default_config = { };
      http = {
        use_x_forwarded_for = true;
        trusted_proxies = [
          "127.0.0.1"
          "::1"
        ];
      };
    };
    configWritable = true;
  };
}
