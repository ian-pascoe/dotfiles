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
          "systemctl --user restart org.nix-community.home.opencode-web.service"
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
      ProgramArguments = [
        "${config.programs.zsh.package}/bin/zsh"
        "-lic"
        "opencode web"
      ];
    };
  };

  systemd.user.services.opencode-web = {
    Unit = {
      Description = "OpenCode Web Interface";
    };
    Service = {
      ExecStart = "${config.programs.zsh.package}/bin/zsh -lic 'opencode web'";
    };
  };
}
