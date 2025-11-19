{
  pkgs,
  config,
  dotfiles,
  ...
}:
{
  programs.neovim = {
    enable = true;
    extraPackages = with pkgs; [
      tree-sitter
    ];
    defaultEditor = true;
    vimAlias = true;
    vimdiffAlias = true;
  };

  xdg.configFile.nvim = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfiles.path}/config/nvim";
    force = true;
  };
}
