{
  imports = [
    ./packages
    ./programs
  ];
  home = {
    shell = {
      enableShellIntegration = true;
    };
    shellAliases = {
      nfu = "nix flake update --flake ~/.config/nix";
      # Garbage collect both system and user profiles
      ncg = "sudo nix-collect-garbage -d && nix-collect-garbage -d";
    };
  };
  xdg.enable = true;
  systemd.user.startServices = "sd-switch";
  home.stateVersion = "25.05";
}
