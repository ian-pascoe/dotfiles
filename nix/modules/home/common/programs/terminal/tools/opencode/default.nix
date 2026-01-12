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

  home.file = {
    ".local/bin/sync-copilot-tokens" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfiles.path}/bin/sync-copilot-tokens";
      force = true;
    };
  };

  xdg.configFile = {
    opencode = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfiles.path}/config/opencode";
      force = true;
    };
  };

  home = {
    shellAliases.oc = "opencode";

    activation = {
      setupSuperpowers = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        if [ ! -d ${config.xdg.configHome}/opencode/superpowers ]; then
          run ${pkgs.git}/bin/git clone https://github.com/obra/superpowers.git ${config.xdg.configHome}/opencode/superpowers
        else
          run ${pkgs.git}/bin/git -C ${config.xdg.configHome}/opencode/superpowers pull
        fi
        run ln -snf ${config.xdg.configHome}/opencode/superpowers/.opencode/plugin/superpowers.js ${config.xdg.configHome}/opencode/plugin/superpowers.js
      '';
    };
  };
}
