{
  config,
  dotfiles,
  pkgs,
  ...
}: {
  imports = [
    ../../../../../util/home/dotfiles
  ];
  programs.rofi = {
    enable = pkgs.stdenv.isLinux; # mac install handled via homebrew
  };
  xdg.configFile.rofi = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfiles.path}/.config/rofi";
    force = true;
  };
}
