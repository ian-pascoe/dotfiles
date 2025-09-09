{
  config,
  dotfiles,
  ...
}: {
  imports = [
    ../../../../../util/home/dotfiles
  ];
  programs.sketchybar = {
    enable = true;
    configType = "lua";
    config = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfiles.path}/.config/sketchybar";
    };
  };
  home.shellAliases = {
    restart-sketchybar = ''launchctl kickstart -k gui/"$(id -u)"/org.nix-community.home.sketchybar'';
  };
}
