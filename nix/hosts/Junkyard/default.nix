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
    ./home-assistant.nix
    (lib.module.findModules ../../modules/common)
    (lib.module.findModules ../../modules/nixos)
  ];

  sops = {
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    secrets = {
      "cloudflared/cert.pem" = {
        sopsFile = ../../secrets/Junkyard/cloudflared.yaml;
        format = "yaml";
      };
      "cloudflared/junkyard-server.json" = {
        sopsFile = ../../secrets/Junkyard/cloudflared.yaml;
        format = "yaml";
      };
    };
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

  # Uncomment once you have set up cloudflared tunnel
  services = {
    cloudflared = {
      enable = true;
      # Run: `cloudflared login` to generate this cert.pem file
      certificateFile = config.sops.secrets."cloudflared/cert.pem".path;
      tunnels = {
        junkyard-server = {
          credentialsFile = config.sops.secrets."cloudflared/junkyard-server.json".path;
          default = "http_status:404";
          ingress = {
            # Run: `cloudflared tunnel route dns junkyard-server home-assistant.ianpascoe.dev`
            "home-assistant.ianpascoe.dev" = {
              service = "http://localhost:8123";
            };
            # Run: `cloudflared tunnel route dns junkyard-server junkyard-ssh.ianpascoe.dev`
            "junkyard-ssh.ianpascoe.dev" = {
              service = "ssh://localhost:22";
            };
          };
        };
      };
    };

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
