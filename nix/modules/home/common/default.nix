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

    sessionPath = [
      "$XDG_BIN_HOME"
    ];
  };

  systemd.user.startServices = "sd-switch";

  home.stateVersion = "25.05";
}
