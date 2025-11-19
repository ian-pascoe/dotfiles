{
  config,
  dotfiles,
  ...
}:
{
  programs.bat = {
    enable = true;
  };

  xdg.configFile.bat = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfiles.path}/config/bat";
    force = true;
  };

  home.shellAliases = {
    cat = "bat --paging=never";
  };
}
