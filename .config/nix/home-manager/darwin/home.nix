{pkgs, ...}: let
  terminalBackground = pkgs.fetchurl {
    url = "https://images8.alphacoders.com/135/1351417.png";
    sha256 = "sha256-tKNdnOxEwoyc3mtPrGnahDWe4ZwzaVtrPACaNUT4UTo=";
  };
in {
  imports = [../modules/common-home.nix];

  home = {
    packages = with pkgs; [
      darwin.libiconv
    ];

    file = {
      ".config/ghostty/config" = {
        enable = true;
        text = ''
          font-family = "JetBrainsMono Nerd Font Mono"
          font-size = 14
          background-image = "${terminalBackground}"
          background-image-fit = cover
          background-image-opacity = 0.1
        '';
      };
    };

    shellAliases = {
      nds = "sudo nix run nix-darwin/master#darwin-rebuild -- switch --flake ~/.config/nix#Ians-Macbook-Pro";
    };

    sessionVariables = {
      EDITOR = "nvim";
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
