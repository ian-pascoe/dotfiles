{
  config,
  dotfiles,
  ...
}: {
  imports = [
    ../../../../../util/home/dotfiles
  ];
  programs.borders = {
    enable = true;
  };
  xdg.configFile.borders = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfiles.path}/.config/borders";
    force = true;
  };
}
