{
  config,
  lib,
  dotfiles,
  ...
}:
{
  imports = [
    ../../../util/home/dotfiles
  ];

  home = {
    file = {
      ".themes" = {
        source = config.lib.file.mkOutOfStoreSymlink "${dotfiles.path}/themes";
        force = true;
      };
      ".local/bin/set-theme" = {
        source = config.lib.file.mkOutOfStoreSymlink "${dotfiles.path}/bin/set-theme";
        force = true;
      };
      ".local/bin/set-bg" = {
        source = config.lib.file.mkOutOfStoreSymlink "${dotfiles.path}/bin/set-bg";
        force = true;
      };
    };

    activation = {
      "setTheme" = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        export PATH="${config.home.path}/bin:${config.home.homeDirectory}/.local/bin:/usr/bin:/bin:$PATH"
        if [ ! -d "${config.xdg.configHome}/theme" ]; then
          echo "Applying Rose Pine (default) theme"
          run "${config.home.homeDirectory}/.local/bin/set-theme" rose-pine
        else
          echo "Re-applying current theme in case there are changes"
          theme=$(readlink "${config.xdg.configHome}/theme" | xargs basename)
          run "${config.home.homeDirectory}/.local/bin/set-theme" "$theme"
        fi
      '';
    };
  };
}
