{
  pkgs,
  lib,
  config,
  ...
}:
let
  wallpaperDir = "${config.home.homeDirectory}/.config/theme/backgrounds";
  rotationIntervalSeconds = 600; # 10 minutes
  randomOrder = false; # set true to shuffle

  setWallpaperScript = pkgs.writeShellScriptBin "set-wallpaper" ''
    #!/usr/bin/env sh
    WALLPAPER_DIR="${wallpaperDir}"

    if [ ! -d "$WALLPAPER_DIR" ]; then
      echo "Wallpaper directory not found: $WALLPAPER_DIR"
      exit 0
    fi

    /usr/bin/osascript <<EOF
    tell application "System Events"
      repeat with d in desktops
        set picture rotation of d to 1 -- 0: never, 1: interval, 2: login, 3: sleep
        set change interval of d to ${toString rotationIntervalSeconds}
        set random order of d to ${if randomOrder then "true" else "false"}
        set pictures folder of d to POSIX file "${wallpaperDir}"
      end repeat
    end tell
    EOF

    echo "Configured desktop slideshow from: $WALLPAPER_DIR"
  '';
in
{
  home = {
    activation = {
      "setWallpaper" = lib.hm.dag.entryAfter [ "setTheme" ] ''
        echo "Configuring desktop wallpaper slideshow"
        ${setWallpaperScript}/bin/set-wallpaper
      '';
    };
  };
}
