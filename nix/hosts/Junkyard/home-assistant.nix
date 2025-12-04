{
  pkgs,
  config,
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
  sops = {
    secrets = {
      "home-assistant/google-assistant/service-account.json" = {
        sopsFile = ../../secrets/Junkyard/home-assistant.yaml;
        format = "yaml";
        owner = "hass";
        group = "hass";
      };
      "home-assistant/openid/client-id" = {
        sopsFile = ../../secrets/Junkyard/home-assistant.yaml;
        format = "yaml";
        owner = "hass";
        group = "hass";
      };
      "home-assistant/openid/client-secret" = {
        sopsFile = ../../secrets/Junkyard/home-assistant.yaml;
        format = "yaml";
        owner = "hass";
        group = "hass";
      };
    };
  };

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
        bidict
        gehomesdk
        grpcio
        grpclib
        gtts
        hatch-rest-api
        ibeacon-ble
        magicattr
        sharkiq
      ];
    extraComponents = [
      "default_config"
      "asuswrt"
      "caldav"
      "cast"
      "cloudflare"
      "cync"
      "denon"
      "denonavr"
      "esphome"
      "google"
      "google_assistant"
      "google_assistant_sdk"
      "google_generative_ai_conversation"
      "homekit"
      "homekit_controller"
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
      "ring"
      "roku"
      "sharkiq"
      "spotify"
      "tuya"
      "webdav"
      "wyoming"
      "youtube"
    ];
    customComponents = with pkgs.home-assistant-custom-components; [
      hacs
      spook
    ];
    config = {
      default_config = { };
      automation = "!include automations.yaml";
      media_dirs = {
        media = "media";
        recording = "recording";
      };
      http = {
        use_x_forwarded_for = true;
        trusted_proxies = [
          "127.0.0.1"
          "::1"
        ];
      };
      openid = {
        client_id = "!include ${config.sops.secrets."home-assistant/openid/client-id".path}";
        client_secret = "!include ${config.sops.secrets."home-assistant/openid/client-secret".path}";
        configure_url = "https://auth.ianpascoe.dev/realms/master/.well-known/openid-configuration";
        username_field = "preferred_username";
        scope = "openid profile email";
        block_login = false; # Block default login
        openid_text = "Login with Keycloak";
      };
      google_assistant = {
        project_id = "pascoe-family";
        service_account = "!include ${
          config.sops.secrets."home-assistant/google-assistant/service-account.json".path
        }";
        report_state = true;
      };
    };
    configWritable = true;
  };
}
