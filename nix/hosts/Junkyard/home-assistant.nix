{ pkgs, ... }:
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
