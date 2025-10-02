{
  pkgs,
  config,
  dotfiles,
  ...
}:
{
  imports = [
    ../../../../../util/home/dotfiles
  ];
  programs.sketchybar = {
    enable = true;
    configType = "lua";
    extraPackages = with pkgs; [
      aerospace
      blueutil
      uutils-coreutils
    ];
    config = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfiles.path}/.config/sketchybar";
      recursive = true;
    };
  };
  home.shellAliases = {
    restart-sketchybar = ''launchctl kickstart -k gui/"$(id -u)"/org.nix-community.home.sketchybar'';
  };
}
