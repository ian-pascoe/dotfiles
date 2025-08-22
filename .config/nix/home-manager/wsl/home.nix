# This is your home-manager configuration file
# Use this to configure your home environment (it replaces ~/.config/nixpkgs/home.nix)
{pkgs, ...}: let
  certs = pkgs.fetchzip {
    url = "https://pki.rtx.com/certificate/RTX_Cert_Bundle-current.zip";
    sha256 = "sha256-4UqqonCQThHkt5dsq3FQJrUWP0D07mmlDdBjmTTlRmY=";
  };
  pemFiles =
    map (f: "${certs}/PEM/${f}")
    (builtins.filter (f: f != "." && f != ".." && f != "README.txt" && builtins.match ".+\\.cer$" f != null)
      (builtins.attrNames (builtins.readDir "${certs}/PEM")));
  rtxCacerts =
    pkgs.runCommand "rtx-cacerts" {
      buildInputs = [
        pkgs.jdk
      ];
    } ''
      set -eu
      mkdir work
      cp ${pkgs.jdk}/lib/openjdk/lib/security/cacerts work/orig
      cp work/orig cacerts
      chmod +w cacerts
      for f in ${builtins.concatStringsSep " " pemFiles}; do
        alias=$(basename "$f" | sed -e 's/\.[cC][eE][rR]$//' -e 's/[^A-Za-z0-9_.-]/_/g')
        ${pkgs.jdk}/bin/keytool -importcert -noprompt \
          -keystore cacerts -storepass changeit \
          -file "$f" -alias "$alias" 2>/dev/null
      done
      mkdir -p $out/lib/openjdk/lib/security
      cp cacerts $out/lib/openjdk/lib/security/cacerts
    '';

  trustStore = "${rtxCacerts}/lib/openjdk/lib/security/cacerts";
in {
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
      enableShellIntegration = true;
    };
    packages = with pkgs; [
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
      libiconv
      git-credential-manager
      (pkgs.writeShellScriptBin "mcp-hub-installer" ''
        #!/bin/bash
        npm install -g mcp-hub@latest
      '')
    ];
  };

  programs.home-manager.enable = true;
  programs.git = {
    enable = true;
    lfs.enable = true;
    extraConfig = {
      user.email = "ian.pascoe@rtx.com";
      user.name = "Ian Pascoe";
      credential = {
        helper = "manager";
        credentialStore = "cache";
        "https://github.com".username = "ian-pascoe";
        "https://github-us.utc.com".username = "e21146146";
      };
    };
  };
  programs.gh.enable = true;
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    envExtra = ''
      export http_proxy="http://REDACTED:80/"
      export https_proxy="http://REDACTED:80/"
      export HTTP_PROXY="http://REDACTED:80/"
      export HTTPS_PROXY="http://REDACTED:80/"
      export all_proxy="http://REDACTED:80/"
      export ALL_PROXY="http://REDACTED:80/"
      export no_proxy="localhost,127.0.0.1,.raytheon.com,.ray.com,.rtx.com,.utc.com,.adxrt.com,.registry.npmjs.org,.eks.amazonaws.com"
      export NO_PROXY="localhost,127.0.0.1,.raytheon.com,.ray.com,.rtx.com,.utc.com,.adxrt.com,.registry.npmjs.org,.eks.amazonaws.com"
      export SSL_CERT_FILE="/etc/ssl/certs/ca-certificates.crt"
      export SSL_CERT_DIR="/etc/ssl/certs"
      export REQUESTS_CA_BUNDLE="/etc/ssl/certs/ca-certificates.crt"
      export JAVAX_NET_SSL_TRUSTSTORE="${trustStore}"
    '';
    shellAliases = {
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
  programs.java.enable = true;
  programs.gradle = {
    enable = true;
    settings = {
      "systemProp.http.proxyHost" = "REDACTED";
      "systemProp.http.proxyPort" = "80";
      "systemProp.https.proxyHost" = "REDACTED";
      "systemProp.https.proxyPort" = "80";
      "systemProp.http.nonProxyHosts" = "localhost|*.raytheon.com|*.ray.com|*.rtx.com|*.utc.com|*.adxrt.com|registry.npmjs.org|eks.amazonaws.com";
      "systemProp.https.nonProxyHosts" = "localhost|*.raytheon.com|*.ray.com|*.rtx.com|*.utc.com|*.adxrt.com|registry.npmjs.org|eks.amazonaws.com";
      "systemProp.javax.net.ssl.trustStore" = "${trustStore}";
      "systemProp.http.connectionTimeout" = "120000";
      "systemProp.http.socketTimeout" = "120000";
      "systemProp.https.connectionTimeout" = "120000";
      "systemProp.https.socketTimeout" = "120000";
    };
  };
  programs.opencode.enable = true;
  programs.uv.enable = true;

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "25.05";
}
