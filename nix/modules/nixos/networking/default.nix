{ lib, ... }:
{
  networking = {
    networkmanager = {
      enable = lib.mkDefault true;
      wifi.backend = "wpa_supplicant";
    };
    useDHCP = lib.mkDefault true;
  };
}
