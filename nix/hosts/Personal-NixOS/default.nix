{
  lib,
  pkgs,
  username,
  ...
}:
{
  imports = lib.flatten [
    ./hardware.nix
    (lib.module.findModules ../../modules/common)
    (lib.module.findModules ../../modules/nixos)
  ];

  networking.hostName = "Personal-NixOS";

  nixpkgs.hostPlatform = "x86_64-linux";

  users.users.${username} = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
      "docker"
    ];
    shell = pkgs.zsh;
  };

  # Prevent automatic suspend and lid actions
  services.logind.extraConfig = ''
    IdleAction=ignore
    IdleActionSec=0
    HandleLidSwitch=ignore
    HandleLidSwitchDocked=ignore
    HandleHibernateKey=ignore
    HandleSuspendKey=ignore
  '';

  systemd.sleep.extraConfig = ''
    AllowSuspend=no
    AllowHibernation=no
    AllowHybridSleep=no
    AllowSuspendThenHibernate=no
  '';
}
