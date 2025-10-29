{
  config,
  lib,
  dotfiles,
  ...
}:
{
  imports = [
    ../../../util/home/dotfiles
    ./wallpaper
  ];

  home = {
    file = {
      ".themes" = {
        source = config.lib.file.mkOutOfStoreSymlink "${dotfiles.path}/themes";
        force = true;
      };
      ".local/bin/set-theme" = {
        source = config.lib.file.mkOutOfStoreSymlink "${dotfiles.path}/bin/set-theme.sh";
        force = true;
      };
    };

    activation = {
      "setTheme" = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        if [ ! -d ${config.home.homeDirectory}/.config/theme ]; then
          echo "Applying theme settings"
          ${config.home.homeDirectory}/.local/bin/set-theme rose-pine
        else
          echo "Theme directory already exists, skipping theme setup"
        fi
      '';
    };
  };
}
