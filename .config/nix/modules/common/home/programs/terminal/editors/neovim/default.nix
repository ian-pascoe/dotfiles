{
  config,
  dotfiles,
  ...
}: {
  imports = [
    ../../../../../../util/home/dotfiles
  ];
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    vimAlias = true;
    vimdiffAlias = true;
  };
  xdg.configFile.nvim = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfiles.path}/.config/nvim";
    recursive = true;
    force = true;
  };
}
