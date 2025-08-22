{pkgs, ...}: {
  imports = [../../modules/common-home.nix];

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
          background-image = "/Users/ianpascoe/Pictures/terminal-background.png"
          background-image-fit = cover
          background-image-opacity = 0.1
        '';
      };
    };

    shellAliases = {
      nds = "sudo nix run nix-darwin/master#darwin-rebuild --extra-experimental-features 'nix-command flakes' -- switch --flake ~/.config/nix#Ians-Macbook-Pro";
    };

    sessionVariables = {
      EDITOR = "nvim";
    };
  };

  programs.bash.enable = true;
  programs.zsh.enable = true;

  programs.git.extraConfig = {
    credential = {
      helper = "manager";
      credentialStore = "cache";
      "https://github.com".username = "ian-pascoe";
    };
  };

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";
}
