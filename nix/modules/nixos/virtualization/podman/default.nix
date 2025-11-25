{ pkgs, lib, ... }:
{
  virtualisation.podman = {
    enable = lib.mkDefault true;
    dockerCompat = lib.mkDefault true;
    dockerSocket.enable = lib.mkDefault true;
    defaultNetwork.settings.dns_enabled = lib.mkDefault true;
    autoPrune = {
      enable = lib.mkDefault true;
      dates = lib.mkDefault "weekly";
    };
  };

  environment.systemPackages = with pkgs; [
    dive
    podman-tui
    podman-compose
  ];
}
