{pkgs, ...}: {
  home.packages = with pkgs; [
    pkg-config
    unzip
    lsof
    nodejs_24
    go
    python3Full
    rustc
    cargo
    nixd
    alejandra
    gcc
    git-credential-manager
    gnupg
    pass
    (pkgs.writeShellScriptBin "mcp-hub-installer" ''
      #!/bin/bash
      if ! command -v mcp-hub &> /dev/null; then
        echo "Installing mcp-hub globally..."
        npm install -g mcp-hub@latest
      fi
    '')
  ];

  programs = {
    home-manager.enable = true;
    zsh = {
      enable = true;
      autosuggestion.enable = true;
    };
    starship.enable = true;
    lsd.enable = true;
    bat = {
      enable = true;
      config.theme = "Nord";
    };
    ripgrep.enable = true;
    fzf.enable = true;
    zoxide.enable = true;
    neovim = {
      enable = true;
      defaultEditor = true;
      vimAlias = true;
      vimdiffAlias = true;
    };
    bun.enable = true;
    opencode.enable = true;
    uv.enable = true;
    gh.enable = true;
    git = {
      enable = true;
      lfs.enable = true;
    };
    java.enable = true;
    gradle.enable = true;
  };

  home = {
    shell.enableShellIntegration = true;
    shellAliases = {
      cat = "bat --pager=never";
      cd = "z";
    };
  };

  programs.gpg = {
    enable = true;
    settings = {
      trust-model = "tofu+pgp";
    };
  };

  services.gpg-agent = {
    enable = true;
    defaultCacheTtl = 1800;
    enableSshSupport = true;
    pinentry.package = pkgs.pinentry-curses;
  };

  programs.password-store = {
    enable = true;
    settings = {
      PASSWORD_STORE_DIR = "$HOME/.password-store";
    };
  };

  # Auto-setup script for GPG and pass
  home.activation.setupGitCredentials = ''
    if [ ! -f "$HOME/.gpg-key-generated" ]; then
      $DRY_RUN_CMD ${pkgs.gnupg}/bin/gpg --batch --generate-key <<EOF
    %no-protection
    Key-Type: RSA
    Key-Length: 2048
    Subkey-Type: RSA
    Subkey-Length: 2048
    Name-Real: Ian Pascoe (Git Credentials)
    Name-Email: ian.g.pascoe@gmail.com
    Expire-Date: 0
    %commit
    EOF
      touch "$HOME/.gpg-key-generated"

      # Initialize password store with the generated key
      KEY_ID=$(${pkgs.gnupg}/bin/gpg --list-secret-keys --keyid-format LONG | grep sec | head -n1 | sed 's/.*\/\([^ ]*\) .*/\1/')
      $DRY_RUN_CMD ${pkgs.pass}/bin/pass init "$KEY_ID"
    fi
  '';

  systemd.user.startServices = "sd-switch";
  home.stateVersion = "25.05";
}
