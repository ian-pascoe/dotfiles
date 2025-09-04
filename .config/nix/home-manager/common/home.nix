{
  pkgs,
  config,
  lib,
  ...
}: let
  dotfiles = "${config.home.homeDirectory}/dotfiles";
in {
  home.packages = with pkgs; [
    pkg-config
    unzip
    fd
    lsof
    nodejs_24
    go
    python3Full
    rustc
    cargo
    nixd
    alejandra
    gcc
    gnumake
    git-credential-manager
    gnupg
    pass
  ];

  programs = {
    home-manager.enable = true;
    zsh = {
      enable = true;
      autosuggestion.enable = true;
    };
    starship.enable = true;
    lsd.enable = true;
    bat.enable = true;
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
    uv.enable = true;
    gh.enable = true;
    git.enable = true;
    git.lfs.enable = true;
    lazygit.enable = true;
    awscli.enable = true;
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

  home.activation.cloneDotfiles = lib.hm.dag.entryAfter ["writeBoundary"] ''
    if [ ! -d "${dotfiles}" ]; then
      ${pkgs.git}/bin/git clone https://github.com/ian-pascoe/dotfiles.git "${dotfiles}"
    else
      (cd "${dotfiles}" && ${pkgs.git}/bin/git pull --ff-only)
    fi
  '';
  home.file = {
    ".config/bat".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/bat";
    ".config/k9s".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/k9s";
    ".config/karabiner".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/karabiner";
    ".config/lsd".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/lsd";
    ".config/nix".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/nix";
    ".config/nvim".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/nvim";
    ".config/opencode".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/opencode";
    ".config/starship.toml".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/starship.toml";
  };

  xdg.enable = true;

  systemd.user.startServices = "sd-switch";
  home.stateVersion = "25.05";
}
