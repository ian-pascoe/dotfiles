{
  config,
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
    name = "${username}";
    home = "/home/${username}";
    extraGroups = [
      "wheel"
      "networkmanager"
      "docker"
    ];
    shell = pkgs.zsh;
  };

  networking.firewall.enable = false;

  environment.systemPackages = with pkgs; [
    cloudflared
  ];
  services.cloudflared = {
    enable = true;
    certificateFile = "${config.users.users.${username}.home}/.cloudflared/cert.pem"; # You must run `cloudflared login` first to generate this file
  };

  # Prevent automatic suspend and lid actions
  services.logind = {
    settings.Login = {
      IdleAction = "ignore";
      IdleActionSec = 0;
      HandleLidSwitch = "ignore";
      HandleLidSwitchDocked = "ignore";
      HandleHibernateKey = "ignore";
      HandleSuspendKey = "ignore";
    };
  };

  systemd.sleep.extraConfig = ''
    AllowSuspend=no
    AllowHibernation=no
    AllowHybridSleep=no
    AllowSuspendThenHibernate=no
  '';
}
