{
  pkgs,
  config,
  dotfiles,
  ...
}: {
  imports = [
    ../../../../../util/home/dotfiles
  ];
  home.packages = with pkgs; [
    karabiner-elements
  ];
  xdg.configFile.karabiner = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfiles.path}/.config/karabiner";
    force = true;
  };
}
