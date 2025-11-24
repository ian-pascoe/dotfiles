{
  pkgs,
  config,
  lib,
  dotfiles,
  ...
}:
let
  tmuxPluginManager = pkgs.fetchFromGitHub {
    owner = "tmux-plugins";
    repo = "tpm";
    rev = "master";
    sha256 = "sha256-hW8mfwB8F9ZkTQ72WQp/1fy8KL1IIYMZBtZYIwZdMQc=";
  };
in
{
  programs.tmux = {
    enable = lib.mkDefault true;
  };

  xdg.configFile = {
    "tmux/tmux.conf" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfiles.path}/config/tmux/tmux.conf";
      force = true;
    };
    "tmux/plugins/tpm" = {
      source = tmuxPluginManager;
      force = true;
    };
  };
}
