{
  config,
  dotfiles,
  ...
}: {
  imports = [
    ../../../../../util/home/dotfiles
  ];
  services.jankyborders = {
    enable = true;
  };
  xdg.configFile."borders/bordersrc" = {
    enable = false; # disable automatic generation of bordersrc
  };
  xdg.configFile.borders = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfiles.path}/.config/borders";
    force = true;
  };
  home.shellAliases = {
    restart-borders = ''launchctl kickstart -k gui/"$(id -u)"/org.nix-community.home.jankyborders'';
  };
}
