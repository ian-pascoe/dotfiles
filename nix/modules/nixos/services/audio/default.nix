{ lib, ... }:
{
  services = {
    pipewire = {
      enable = lib.mkDefault true;
      alsa.enable = lib.mkDefault true;
      alsa.support32Bit = lib.mkDefault true;
      pulse.enable = lib.mkDefault true;
    };
    pulseaudio = {
      enable = lib.mkDefault false;
    };
  };
}
