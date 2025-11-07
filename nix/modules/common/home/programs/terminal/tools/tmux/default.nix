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
      source = pkgs.tmuxPlugins.continuum;
    };
    "tmux/plugins/resurrect" = {
      source = pkgs.tmuxPlugins.resurrect;
    };
  };
}
