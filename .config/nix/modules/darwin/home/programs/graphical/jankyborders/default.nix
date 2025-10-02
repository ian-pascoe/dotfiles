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
  services.jankyborders = {
    enable = true;
  };
  launchd.agents.jankyborders = {
    config = {
      EnvironmentVariables = {
        PATH = "/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:${pkgs.jankyborders}/bin";
      };
    };
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
