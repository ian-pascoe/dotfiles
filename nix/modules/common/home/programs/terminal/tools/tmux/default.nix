{ config, dotfiles, ... }:
{
  imports = [
    ../../../../../../util/home/dotfiles
  ];

  programs.tmux = {
    enable = true;
  };

  home.file = {
    ".tmux.conf" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfiles.path}/config/.tmux.conf";
      force = true;
    };
  };
}
