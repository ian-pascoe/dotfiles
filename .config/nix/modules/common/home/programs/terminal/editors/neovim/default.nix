{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    vimAlias = true;
    vimdiffAlias = true;
  };
  xdg.configFile.nvim = {
    source = ./config;
    recursive = true;
  };
}
