{
  pkgs,
  config,
  hacs,
  buildCustomPythonPackages,
  ...
}:
{
  imports = [
    ./custom-components.nix
    ./custom-python-packages.nix
  ];

  sops = {
    secrets = {
      "home-assistant/google-assistant/service-account.json" = {
        sopsFile = ../../../secrets/Junkyard/home-assistant.yaml;
        format = "yaml";
        owner = "hass";
        group = "hass";
      };
      "home-assistant/openid/client-id" = {
        sopsFile = ../../../secrets/Junkyard/home-assistant.yaml;
        format = "yaml";
        owner = "hass";
        group = "hass";
      };
      "home-assistant/openid/client-secret" = {
        sopsFile = ../../../secrets/Junkyard/home-assistant.yaml;
        format = "yaml";
        owner = "hass";
        group = "hass";
      };
    };
  };

  services = {
    home-assistant = {
      enable = true;
      extraPackages =
        basePythonPackages:
        let
          pythonPackages = buildCustomPythonPackages basePythonPackages;
        in
        with pythonPackages;
        [
          bidict
          gehomesdk
          grpcio
          grpclib
          gtts
          hatch-rest-api
          magicattr
          sharkiq
        ];
      extraComponents = [
        "default_config"
        "apple_tv"
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
        "heos"
        "homekit"
        "homekit_controller"
        "ibeacon"
        "icloud"
        "met"
        "mqtt"
        "myq"
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
        "sentry"
        # "sharkiq" # TODO: Put this back once the package is updated
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
        homeassistant = {
          media_dirs = {
            media = "media";
            recordings = "recordings";
          };
        };
        automation = "!include automations.yaml";
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

    wyoming = {
      faster-whisper.servers = {
        "home-assistant" = {
          enable = true;
          uri = "tcp://0.0.0.0:10300";
          device = "auto";
          language = "en";
          model = "tiny.en";
        };
      };

      piper.servers = {
        "home-assistant" = {
          enable = true;
          uri = "tcp://0.0.0.0:10301";
          streaming = true;
          voice = "en-us-ryan-medium";
        };
      };
    };
  };

  networking.firewall = {
    allowedTCPPorts = [
      8123 # Web UI
      10300 # Wyoming faster-whisper
      10301 # Wyoming piper
      5540 # Matter
      8009 # Chromecast
      6053 # Esphome
      8266 # Esphome
    ];
    allowedTCPPortRanges = [
      # Homekit bridge
      {
        from = 21063;
        to = 21070;
      }
    ];
    # Needed for device discovery
    allowedUDPPorts = [
      1900 # SSDP
      5353 # mDNS
      67 # DHCP
      68 # DHCP
      6666 # Tuya local API
      6667 # Tuya local API secure
      5540 # Matter
      21063 # Matter over IP fabric
      5683 # Thread/Coap
      5684 # Thread/Coap
    ];
  };
}
