{
  pkgs,
  lib,
  ...
}:
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
      pythonPackages:
      let
        # TODO: Remove this once newer package is available
        customPythonPackages = pythonPackages.overrideScope (
          pyFinal: pyPrev: {
            gehomesdk = pyPrev.buildPythonPackage rec {
              pname = "gehomesdk";
              version = "2025.11.5";
              pyproject = true;

              disabled = pyPrev.pythonOlder "3.9";

              src = pyPrev.fetchPypi {
                inherit pname version;
                hash = "sha256-HS33yTE+3n0DKRD4+cr8zAE+xcW1ca7q8inQ7qwKJMA=";
              };

              build-system = with pyPrev; [ setuptools ];

              dependencies = with pyPrev; [
                aiohttp
                beautifulsoup4
                bidict
                humanize
                lxml
                requests
                slixmpp
                websockets
              ];

              # Tests are not shipped and source is not tagged
              # https://github.com/simbaja/gehome/issues/32
              doCheck = false;

              pythonImportsCheck = [ "gehomesdk" ];
            };
            magicattr = pyPrev.buildPythonPackage rec {
              pname = "magicattr";
              version = "0.1.6";
              pyproject = true;

              disabled = pyPrev.pythonOlder "3.9";

              src = pkgs.fetchFromGitHub {
                owner = "frmdstryr";
                repo = "magicattr";
                rev = "v${version}";
                hash = "sha256-hV425AnXoYL3oSYMhbXaF8VRe/B1s5f5noAZYz4MMwc=";
              };

              build-system = with pyPrev; [ setuptools ];

              pythonImportsCheck = [ "magicattr" ];
            };
            hatch-rest-api = pyPrev.buildPythonPackage rec {
              pname = "hatch-rest-api";
              version = "1.30.0";
              pyproject = true;

              disabled = pyPrev.pythonOlder "3.9";

              src = pkgs.fetchFromGitHub {
                owner = "dahlb";
                repo = "hatch_rest_api";
                rev = "v${version}";
                hash = "sha256-9FJSlFpsfNbFJ5b/IPBAt6rBAAhtuXYrTw0qrPMiOf4=";
              };

              build-system = with pyPrev; [ setuptools ];

              dependencies = with pyPrev; [
                wheel
                ruff
                aiohttp
                awsiotsdk
              ];

              pythonImportsCheck = [ "hatch_rest_api" ];
            };
          }
        );
      in
      with customPythonPackages;
      [
        gtts
        grpclib
        grpcio
        sharkiq
        ibeacon-ble
        bidict
        gehomesdk
        magicattr
        hatch-rest-api
      ];
    extraComponents = [
      "default_config"
      "asuswrt"
      "caldav"
      "cloudflare"
      "cync"
      "denon"
      "denonavr"
      "esphome"
      "google_generative_ai_conversation"
      "ibeacon"
      "icloud"
      "met"
      "mqtt"
      "nest"
      "nextcloud"
      "nextdns"
      "nmap_tracker"
      "ntfy"
      "open_router"
      "openai_conversation"
      "openweathermap"
      "remote"
      "roku"
      "sharkiq"
      "spotify"
      "tuya"
      "webdav"
    ];
    customComponents = with pkgs.home-assistant-custom-components; [
      hacs
      spook
    ];
    config = {
      default_config = { };
      automation = "!include automations.yaml";
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
