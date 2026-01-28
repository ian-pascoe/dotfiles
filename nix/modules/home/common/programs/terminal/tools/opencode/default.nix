{
  pkgs,
  config,
  lib,
  dotfiles,
  ...
}:
{
  programs.opencode = {
    enable = lib.mkDefault pkgs.stdenv.isLinux; # handled via homebrew on mac
  };

  xdg.configFile = {
    opencode = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfiles.path}/config/opencode";
      force = true;
    };
  };

  home = {
    file = {
      ".local/bin/sync-copilot-tokens" = {
        source = config.lib.file.mkOutOfStoreSymlink "${dotfiles.path}/bin/sync-copilot-tokens";
        force = true;
      };
    };
    shellAliases = {
      oc = "opencode";
      restart-opencode-web =
        if pkgs.stdenv.isLinux then
          "systemctl --user restart opencode-web.service"
        else
          ''launchctl kickstart -k gui/"$(id -u)"/org.nix-community.home.opencode-web'';
    };
    sessionVariables = {
      OPENCODE_EXPERIMENTAL = "1";
    };
  };

  launchd.agents.opencode-web = {
    enable = lib.mkDefault true;
    config = {
      Program = "/opt/homebrew/bin/opencode";
      ProgramArguments = [
        "web"
        "--hostname=0.0.0.0"
        "--port=4096"
      ];
      EnvironmentVariables = {
        PATH = builtins.concatStringsSep ":" [
          "${config.home.homeDirectory}/.local/bin"
          "${config.home.homeDirectory}/.nix-profile/bin"
          "/opt/homebrew/bin"
          "${config.home.path}/bin"
          "/etc/profiles/per-user/${config.home.username}/bin"
          "/run/current-system/sw/bin"
          "/nix/var/nix/profiles/default/bin"
          "/usr/local/sbin"
          "/usr/local/bin"
          "/usr/sbin"
          "/usr/bin"
          "/sbin"
          "/bin"
        ];
        OPENCODE_EXPERIMENTAL = "1";
      };
      RunAtLoad = true;
      WatchPaths = [ "${config.home.homeDirectory}/.config/opencode" ];
      WorkingDirectory = config.home.homeDirectory;
    };
  };

  systemd.user.services.opencode-web = {
    Unit = {
      Description = "OpenCode Web Interface";
    };
    Service = {
      ExecStart = "${pkgs.opencode}/bin/opencode web --hostname=0.0.0.0 --port=4096'";
      Environment = ''
        PATH=${
          builtins.concatStringsSep ":" [
            "${config.home.homeDirectory}/.local/bin"
            "${config.home.homeDirectory}/.nix-profile/bin"
            "${pkgs.opencode}/bin"
            "${config.home.path}/bin"
            "/etc/profiles/per-user/${config.home.username}/bin"
            "/run/current-system/sw/bin"
            "/nix/var/nix/profiles/default/bin"
            "/usr/local/sbin"
            "/usr/local/bin"
            "/usr/sbin"
            "/usr/bin"
            "/sbin"
            "/bin"
          ]
        }
        OPENCODE_EXPERIMENTAL=1
      '';
      WorkingDirectory = config.home.homeDirectory;
      Restart = "always";
    };
  };
}
