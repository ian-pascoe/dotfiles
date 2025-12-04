{
  lib,
  pkgs,
  ...
}:
let
  primaryUser = "ianpascoe";
in
{
  imports = lib.flatten [
    ./hardware.nix
    ./cloudflare-ddns.nix
    ./cloudflared.nix
    ./mosquitto.nix
    ./home-assistant
    (lib.module.findModules ../../modules/common)
    (lib.module.findModules ../../modules/nixos)
  ];

  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

  security.acme = {
    acceptTerms = true;
    defaults.email = "admin@ianpascoe.dev";
  };

  networking = {
    hostName = "Junkyard";
    firewall.enable = true;
  };

  nixpkgs.hostPlatform = "x86_64-linux";

  users.users.${primaryUser} = {
    isNormalUser = true;
    name = "${primaryUser}";
    home = "/home/${primaryUser}";
    extraGroups = [
      "wheel"
      "networkmanager"
      "docker"
    ];
    shell = pkgs.zsh;
  };

  services = {
    logind = {
      settings.Login = {
        IdleAction = "ignore";
        IdleActionSec = 0;
        HandleLidSwitch = "ignore";
        HandleLidSwitchDocked = "ignore";
        HandleHibernateKey = "ignore";
        HandleSuspendKey = "ignore";
      };
    };
  };

  # Prevent automatic suspend and lid actions
  systemd.sleep.extraConfig = ''
    AllowSuspend=no
    AllowHibernation=no
    AllowHybridSleep=no
    AllowSuspendThenHibernate=no
  '';
}
