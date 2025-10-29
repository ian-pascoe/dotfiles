{
  lib,
  ...
}:
{
  home = {
    activation = {
      "setWallpaper" = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        echo "Configuring desktop wallpaper"
        wallpaper ~/.config/theme/backgrounds
      '';
    };
  };
}
