{ config, dotfiles, ... }:
{
  imports = [
    ../../../../../../util/home/dotfiles
  ];

  programs.tmux = {
    enable = true;
  };

  xdg.configFile = {
    "tmux" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfiles.path}/config/tmux";
      force = true;
    };
    "tmux/tmux.conf" = {
      enable = false;
    };
  };
}
