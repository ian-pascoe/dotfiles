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
    ../../modules/common/home/packages
    ../../modules/common/home/programs
  ];

  home = {
    packages = with pkgs; [
      mousecape
    ];

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

    file = {
      ".local/share/sketchybar_lua" = {
        source = "${pkgs.sbarlua}/lib/lua/5.4";
      };
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
  home.stateVersion = "25.05";
}
