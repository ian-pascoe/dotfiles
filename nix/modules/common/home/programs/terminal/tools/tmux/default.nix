{
  pkgs,
  config,
  dotfiles,
  ...
}:
{
  imports = [
    ../../../../../../util/home/dotfiles
  ];

  programs.tmux = {
    enable = true;
  };

  xdg.configFile = {
    "tmux/tmux.conf" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfiles.path}/config/tmux/tmux.conf";
      force = true;
    };
    "tmux/plugins/continuum" = {
      source = "${pkgs.tmuxPlugins.continuum}/share/tmux-plugins/continuum";
    };
    "tmux/plugins/resurrect" = {
      source = "${pkgs.tmuxPlugins.resurrect}/share/tmux-plugins/resurrect";
    };
    "tmux/plugins/tmux-fzf" = {
      source = "${pkgs.tmuxPlugins.fzf}/share/tmux-plugins/tmux-fzf";
    };
  };
}
