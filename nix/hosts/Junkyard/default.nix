{
  config,
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
    (lib.module.findModules ../../modules/common)
    (lib.module.findModules ../../modules/nixos)
  ];

  networking.hostName = "Junkyard";

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

  networking.firewall.enable = false;

  environment.systemPackages = with pkgs; [
    cloudflared
  ];
  services.cloudflared = {
    enable = true;
    certificateFile = "${config.users.users.${primaryUser}.home}/.cloudflared/cert.pem"; # You must run `cloudflared login` first to generate this file
    tunnels = {
      "ianpascoe_dev_server" = {
        credentialsFile = "${
          config.users.users.${primaryUser}.home
        }/.cloudflared/892c7d7e-7cd3-4163-9683-bf5c09ec4c8c.json"; # You must run `cloudflared tunnel create <NAME>` to generate this file
        default = "http_status:404";
        ingress = {
          "junkyard-ssh.ianpascoe.dev" = "ssh://localhost:22";
        };
      };
    };
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
