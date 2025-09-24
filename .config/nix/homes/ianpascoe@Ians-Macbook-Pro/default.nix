{
  pkgs,
  lib,
  ...
}: let
  wallpaper = pkgs.fetchurl {
    url = "https://images8.alphacoders.com/135/1351417.png";
    sha256 = "sha256-tKNdnOxEwoyc3mtPrGnahDWe4ZwzaVtrPACaNUT4UTo=";
  };
  setWallpaperScript = pkgs.writeShellScriptBin "set-wallpaper" ''
    #!/bin/sh
    /usr/bin/osascript -e "tell application \"Finder\" to set desktop picture to POSIX file \"${wallpaper}\""
  '';
in {
  imports = [
    ../../modules/common/home
    ../../modules/darwin/home
  ];

  home = {
    shellAliases = {
      nds = "sudo nix run nix-darwin/master#darwin-rebuild -- switch --flake ~/.config/nix#Ians-Macbook-Pro";
      nfu = "nix flake update --flake ~/.config/nix";
      ncg = "sudo nix-collect-garbage -d";
    };

    activation = {
      "setWallpaper" = lib.hm.dag.entryAfter ["writeBoundary"] ''
        echo "Setting wallpaper"
        ${setWallpaperScript}/bin/set-wallpaper
      '';
    };
  };
}
