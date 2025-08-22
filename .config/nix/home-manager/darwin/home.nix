{ pkgs, ...}: {
    home = {
      shell = {
        enableZshIntegration = true;
        enableNushellIntegration = true;
      };
      packages = with pkgs; [
        unzip
        nodejs_24
        go
        python3Full
        rustc
        cargo
        nixd
        gcc
        git-credential-manager
      ];
    };

    programs.home-manager.enable = true;
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
    programs.zsh.enable = true;
    programs.nushell = {
      enable = true;
      settings = {
        show_banner = false;
        buffer_editor = "nvim";
      };
      shellAliases = {
        ls = "lsd";
        ll = "lsd -Al";
        cat = "bat --pager=never";
        cd = "z";
        nds = "sudo nix run nix-darwin/master#darwin-rebuild --extra-experimental-features 'nix-command flakes' -- switch --flake ~/.config/nix#Ians-Macbook-Pro";
      };
    };
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
  };

