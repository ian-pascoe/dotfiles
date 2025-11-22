{
  config,
  lib,
  dotfiles,
  ...
}:
{
  programs.fastfetch = {
    enable = lib.mkDefault true;
  };

  xdg.configFile = {
    "fastfetch/config.jsonc" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfiles.path}/config/fastfetch/config.jsonc";
    };
  };

  programs.zsh.initContent = lib.mkAfter ''
    fastfetch
  '';
}
