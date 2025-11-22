{ lib, ... }:
{
  programs.home-manager.enable = true;

  xdg.enable = true;

  home = {
    shell = {
      enableShellIntegration = true;
    };

    shellAliases = {
      nfu = "nix flake update --flake ~/.nix";

      # Garbage collect both system and user profiles
      ncg = "sudo -HE nix-collect-garbage -d && nix-collect-garbage -d";

      ".." = "cd ..";
      "..." = "cd ../..";
      "...." = "cd ../../..";
    };

    sessionVariables = {
      XDG_BIN_HOME = "$HOME/.local/bin";
    };

    sessionPath = lib.mkBefore [
      "$XDG_BIN_HOME"
    ];

    file.".hushlogin".text = "";
  };

  systemd.user.startServices = "sd-switch";

  home.stateVersion = "25.05";
}
