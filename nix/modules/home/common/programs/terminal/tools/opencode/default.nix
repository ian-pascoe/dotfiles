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
    };
    sessionVariables = {
      OPENCODE_EXPERIMENTAL = "1";
    };
  };
}
