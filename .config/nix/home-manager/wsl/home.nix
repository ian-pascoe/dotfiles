# This is your home-manager configuration file
# Use this to configure your home environment (it replaces ~/.config/nixpkgs/home.nix)
{
  pkgs,
  rtxCerts,
  ...
}: let
  opencodeLatest = pkgs.stdenv.mkDerivation rec {
    pname = "opencode";
    version = "0.6.3";
    src = pkgs.fetchzip {
      url = "https://github.com/sst/opencode/releases/download/v${version}/opencode-linux-x64.zip";
      hash = "sha256-wrsMOZgWO1lgDSXDLJb0VN0M3itImnP1YSXGAQg51Pg=";
    };
    phases = ["installPhase" "patchPhase"];
    installPhase = ''
      mkdir -p $out/bin
      cp $src/opencode $out/bin/opencode
      chmod +x $out/bin/opencode
    '';
  };
in {
  imports = [
    ../common/home.nix
    ../../modules/nixpkgs-config.nix
    ../../modules/rtx-certs.nix
  ];

  home = {
    username = "1146146";
    homeDirectory = "/home/1146146";

    packages = with pkgs; [
      libiconv
      opencodeLatest
      ant
      maven
      kubectl
      kubernetes-helm
    ];

    shellAliases = {
      nrs = "sudo nixos-rebuild switch --flake ~/.config/nix#EC1414438";
      nfu = "nix flake update --flake ~/.config/nix";
    };
  };

  programs.zsh = {
    envExtra = ''
      # Proxy settings
      export http_proxy="http://REDACTED:80/"
      export https_proxy="http://REDACTED:80/"
      export HTTP_PROXY="http://REDACTED:80/"
      export HTTPS_PROXY="http://REDACTED:80/"
      export all_proxy="http://REDACTED:80/"
      export ALL_PROXY="http://REDACTED:80/"
      export no_proxy="localhost,127.0.0.1,.raytheon.com,.ray.com,.rtx.com,.utc.com,.adxrt.com,.registry.npmjs.org,.eks.amazonaws.com"
      export NO_PROXY="localhost,127.0.0.1,.raytheon.com,.ray.com,.rtx.com,.utc.com,.adxrt.com,.registry.npmjs.org,.eks.amazonaws.com"

      # Used by lemminx
      export HTTP_PROXY_HOST="REDACTED"
      export HTTP_PROXY_PORT="80"

      # SSL certificate settings
      export SSL_CERT_FILE="/etc/ssl/certs/ca-certificates.crt"
      export SSL_CERT_DIR="/etc/ssl/certs"
      export REQUESTS_CA_BUNDLE="/etc/ssl/certs/ca-certificates.crt"
      # Java specific
      export JDK_JAVA_OPTIONS="-Djavax.net.ssl.trustStore=${rtxCerts.trustStore}"
      export JAVA_TOOL_OPTIONS="-Djavax.net.ssl.trustStore=${rtxCerts.trustStore}"
      export JAVA_OPTS="-Djavax.net.ssl.trustStore=${rtxCerts.trustStore}"
      export _JAVA_OPTIONS="-Djavax.net.ssl.trustStore=${rtxCerts.trustStore}"

      # Git Credential Manager settings
      export GCM_CREDENTIAL_STORE="gpg"

      # Ensure GPG agent is available
      export GPG_TTY=$(tty)

      # AWS
      export AWS_PROFILE="saml"
      export AWS_CA_BUNDLE="/etc/ssl/certs/ca-certificates.crt"
    '';
  };

  programs.git.extraConfig = {
    user.email = "ian.pascoe@rtx.com";
    user.name = "Ian Pascoe";
    credential = {
      helper = "manager";
      credentialStore = "gpg";
      "https://github.com".username = "ian-pascoe";
      "https://github.com".provider = "github";
      "https://github-us.utc.com".username = "e21146146";
      "https://github-us.utc.com".provider = "github";
    };
  };

  programs.gradle.settings = {
    "systemProp.http.proxyHost" = "REDACTED";
    "systemProp.http.proxyPort" = "80";
    "systemProp.https.proxyHost" = "REDACTED";
    "systemProp.https.proxyPort" = "80";
    "systemProp.http.nonProxyHosts" = "localhost|*.raytheon.com|*.ray.com|*.rtx.com|*.utc.com|*.adxrt.com|registry.npmjs.org|eks.amazonaws.com";
    "systemProp.https.nonProxyHosts" = "localhost|*.raytheon.com|*.ray.com|*.rtx.com|*.utc.com|*.adxrt.com|registry.npmjs.org|eks.amazonaws.com";
    "systemProp.javax.net.ssl.trustStore" = "${rtxCerts.trustStore}";
    "systemProp.http.connectionTimeout" = "120000";
    "systemProp.http.socketTimeout" = "120000";
    "systemProp.https.connectionTimeout" = "120000";
    "systemProp.https.socketTimeout" = "120000";
  };

  programs.k9s.enable = true;
}
