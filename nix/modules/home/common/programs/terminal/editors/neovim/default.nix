{
  pkgs,
  config,
  lib,
  dotfiles,
  ...
}:
{
  programs.neovim = {
    enable = lib.mkDefault true;
    extraPackages = with pkgs; [
      tree-sitter
    ];
    defaultEditor = lib.mkDefault true;
    vimAlias = lib.mkDefault true;
    vimdiffAlias = lib.mkDefault true;
  };

  xdg.configFile = {
    nvim = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfiles.path}/config/nvim";
      force = true;
    };
  };
}
