{
  lib,
  ...
}:
{
  home = {
    activation = {
      "setWallpaper" = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        echo "Configuring desktop wallpaper"
        /opt/homebrew/bin/wallpaper set ~/.config/theme/backgrounds
      '';
    };
  };
}
