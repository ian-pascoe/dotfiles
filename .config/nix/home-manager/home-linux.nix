# This is your home-manager configuration file
# Use this to configure your home environment (it replaces ~/.config/nixpkgs/home.nix)
{
  inputs,
  lib,
  config,
  pkgs,
  ...
}: {
  nixpkgs = {
    config = {
      allowUnfree = true;
      # Workaround for https://github.com/nix-community/home-manager/issues/2942
      allowUnfreePredicate = _: true;
    };
  };

  home = {
    username = "1146146";
    homeDirectory = "/home/1146146";
    shell = {
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
        "https://github-us.utc.com".username = "e21146146";
      };
    };
  };
  programs.gh.enable = true;
  programs.nushell = {
    enable = true;
    environmentVariables = {
      http_proxy = "http://REDACTED:80/";
      https_proxy = "http://REDACTED:80/";
      HTTP_PROXY = "http://REDACTED:80/";
      HTTPS_PROXY = "http://REDACTED:80/";
      all_proxy = "http://REDACTED:80/";
      ALL_PROXY = "http://REDACTED:80/";
      no_proxy = "localhost,127.0.0.1,.raytheon.com,.ray.com,.rtx.com,.utc.com,.adxrt.com,.registry.npmjs.org,.eks.amazonaws.com";
      NO_PROXY = "localhost,127.0.0.1,.raytheon.com,.ray.com,.rtx.com,.utc.com,.adxrt.com,.registry.npmjs.org,.eks.amazonaws.com";
      SSL_CERT_FILE = "/etc/ssl/certs/ca-certificates.crt";
      SSL_CERT_DIR = "/etc/ssl/certs";
      REQUESTS_CA_BUNDLE = "/etc/ssl/certs/ca-certificates.crt";
    };
    settings = {
      show_banner = false;
      buffer_editor = "nvim";
    };
    shellAliases = {
      ls = "lsd";
      ll = "lsd -Al";
      cat = "bat --pager=never";
      cd = "z";
      nrs = "sudo nixos-rebuild switch --flake ~/.config/nix#EC1414438";
      hms = "home-manager switch --flake ~/.config/nix#1146146@EC1414438";
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
}
