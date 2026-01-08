{
  pkgs,
  config,
  lib,
  dotfiles,
  ...
}:
let
  superpowers = pkgs.fetchFromGitHub {
    owner = "obra";
    repo = "superpowers";
    rev = "v4.0.3";
    hash = "sha256-0/biMK5A9DwXI/UeouBX2aopkUslzJPiNi+eZFkkzXI=";
  };
in
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
    "opencode/opencode.jsonc" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfiles.path}/config/opencode/opencode.jsonc";
      force = true;
    };
    "opencode/oh-my-opencode.jsonc" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfiles.path}/config/opencode/oh-my-opencode.jsonc";
      force = true;
    };
    "opencode/antigravity.json" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfiles.path}/config/opencode/antigravity.json";
      force = true;
    };
    "opencode/agent" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfiles.path}/config/opencode/agent";
      force = true;
    };
    "opencode/command" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfiles.path}/config/opencode/command";
      force = true;
    };
    "opencode/plugin" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfiles.path}/config/opencode/plugin";
      force = true;
    };
    "opencode/skill" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfiles.path}/config/opencode/skill";
      force = true;
    };
    "opencode/superpowers" = {
      source = superpowers;
      force = true;
    };
  };

  home.activation = {
    setupSuperpowers = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      ln -sf ${config.xdg.configHome}/opencode/superpowers/.opencode/plugin/superpowers.js ${config.xdg.configHome}/opencode/plugin/superpowers.js
    '';
  };
}
