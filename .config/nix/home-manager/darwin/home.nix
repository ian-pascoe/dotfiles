{pkgs, ...}: {
  home = {
    packages = with pkgs; [
      pkg-config
      unzip
      nodejs_24
      go
      python3Full
      gcc
      rustc
      cargo
      darwin.libiconv
      nixd
      alejandra
      git-credential-manager
      (pkgs.writeShellScriptBin "mcp-hub-installer" ''
        #!/bin/bash
        if ! command -v mcp-hub &> /dev/null; then
          echo "Installing mcp-hub globally..."
          npm install -g mcp-hub
        fi
      '')
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
    shell = {
      enableShellIntegration = true;
    };
    shellAliases = {
      cat = "bat --pager=never";
      cd = "z";
      nds = "sudo nix run nix-darwin/master#darwin-rebuild --extra-experimental-features 'nix-command flakes' -- switch --flake ~/.config/nix#Ians-Macbook-Pro";
    };
    sessionVariables = {
      EDITOR = "nvim";
    };
  };

  programs.home-manager.enable = true;
  programs.bash.enable = true;
  programs.zsh.enable = true;
  programs.starship.enable = true;
  programs.lsd.enable = true;
  programs.bat = {
    enable = true;
    config = {
      theme = "Nord";
    };
  };
  programs.ripgrep.enable = true;
  programs.fzf.enable = true;
  programs.zoxide.enable = true;
  programs.git = {
    enable = true;
    lfs.enable = true;
    extraConfig = {
      credential = {
        helper = "manager";
        credentialStore = "cache";
        "https://github.com".username = "ian-pascoe";
      };
    };
  };
  programs.gh.enable = true;
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    vimAlias = true;
    vimdiffAlias = true;
  };
  programs.bun.enable = true;
  programs.opencode.enable = true;
  programs.uv.enable = true;

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "25.05";
}
