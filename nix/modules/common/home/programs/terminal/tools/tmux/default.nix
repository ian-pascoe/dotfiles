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
    plugins = with pkgs.tmuxPlugins; [
      continuum
      resurrect
      tmux-fzf
    ];
  };

  xdg.configFile = with pkgs.tmuxPlugins; {
    "tmux/tmux.conf" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfiles.path}/config/tmux/tmux.conf";
      force = true;
    };
    "tmux/plugins/continuum" = {
      source = "${continuum}/share/tmux-plugins/continuum";
    };
    "tmux/plugins/resurrect" = {
      source = "${resurrect}/share/tmux-plugins/resurrect";
    };
    "tmux/plugins/tmux-fzf" = {
      source = "${tmux-fzf}/share/tmux-plugins/tmux-fzf";
    };
  };
}
