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
  libraryPath = lib.makeLibraryPath [
    pkgs.libiconv
    pkgs.icu
  ];
in {
  imports = [../modules/common-home.nix];

  home = {
    sessionVariables = {
      LIBRARY_PATH = ''${libraryPath}''${LIBRARY_PATH:+:$LIBRARY_PATH}'';
    };
    file = {
      ".config/ghostty/config" = {
        enable = true;
        text = ''
          font-family = "JetBrainsMono Nerd Font Mono"
          font-size = 14
          cursor-style = block
          shell-integration-features = no-cursor
          background-image = "${wallpaper}"
          background-image-fit = cover
          background-image-opacity = 0.25
        '';
      };
    };

    shellAliases = {
      nds = "sudo nix run nix-darwin/master#darwin-rebuild -- switch --flake ~/.config/nix#Ians-Macbook-Pro";
      nfu = "nix flake update --flake ~/.config/nix";
    };

    activation = {
      "setWallpaper" = lib.hm.dag.entryAfter ["writeBoundary"] ''
        echo "Setting wallpaper"
        ${setWallpaperScript}/bin/set-wallpaper
      '';
    };
  };

  programs.bash.enable = true;
  programs.zsh = {
    envExtra = ''
      export GCM_CREDENTIAL_STORE="gpg"

      # Ensure GPG agent is available
      export GPG_TTY=$(tty)
    '';
  };

  programs.git.extraConfig = {
    user.email = "ian.g.pascoe@gmail.com";
    user.name = "Ian Pascoe";
    credential = {
      helper = "manager";
      credentialStore = "gpg";
      "https://github.com".username = "ian-pascoe";
    };
  };

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";
}
