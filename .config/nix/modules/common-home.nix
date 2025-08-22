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
  };

  home = {
    shell.enableShellIntegration = true;
    shellAliases = {
      cat = "bat --pager=never";
      cd = "z";
    };
  };

  systemd.user.startServices = "sd-switch";
  home.stateVersion = "25.05";
}

