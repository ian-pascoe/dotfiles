{
  pkgs,
  config,
  dotfiles,
  ...
}: {
  imports = [
    ../../../../../../util/home/dotfiles
  ];
  home.packages = with pkgs; [
    tree-sitter
  ];
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    vimAlias = true;
    vimdiffAlias = true;
  };
  xdg.configFile.nvim = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfiles.path}/.config/nvim";
    force = true;
  };
}
