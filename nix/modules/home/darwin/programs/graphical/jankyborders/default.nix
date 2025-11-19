{
  pkgs,
  config,
  dotfiles,
  ...
}:
{
  services.jankyborders = {
    enable = true;
  };

  launchd.agents.jankyborders = {
    config = {
      EnvironmentVariables = {
        PATH = "${pkgs.jankyborders}/bin:/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin";
      };
    };
  };

  xdg.configFile."borders/bordersrc" = {
    enable = false; # disable automatic generation of bordersrc
  };

  xdg.configFile.borders = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfiles.path}/config/borders";
    force = true;
  };

  home.shellAliases = {
    restart-borders = ''launchctl kickstart -k gui/"$(id -u)"/org.nix-community.home.jankyborders'';
  };
}
