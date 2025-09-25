{
  config,
  dotfiles,
  ...
}: {
  imports = [
    ../../../../util/home/dotfiles
  ];
  programs.rofi = {
    enable = true;
  };
  xdg.configFile.rofi = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfiles.path}/.config/rofi";
    force = true;
  };
}
