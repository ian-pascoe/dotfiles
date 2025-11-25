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

  networking.firewall.enable = true;

  # Uncomment once you have set up cloudflared tunnel
  services.cloudflared = {
    enable = true;
    # Run: `cloudflared login` to generate this cert.pem file
    certificateFile = "${config.users.users.${primaryUser}.home}/.cloudflared/cert.pem";
    tunnels = {
      junkyard-server = {
        # Run: `cloudflared tunnel create --credentials-file="$HOME/.cloudflared/junkyard-server.json" junkyard-server`
        credentialsFile = "${config.users.users.${primaryUser}.home}/.cloudflared/junkyard-server.json";
        default = "http_status:404";
        ingress = {
          # Run: `cloudflared tunnel route dns junkyard-server junkyard-ssh.ianpascoe.dev`
          "junkyard-ssh.ianpascoe.dev" = {
            service = "ssh://localhost:22";
          };
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
