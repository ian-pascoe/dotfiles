# This is your home-manager configuration file
# Use this to configure your home environment (it replaces ~/.config/nixpkgs/home.nix)
{
  pkgs,
  rtxCerts,
  ...
}: {
  imports = [
    ../../modules/common-home.nix
    ../../modules/nixpkgs-config.nix
    ../../modules/rtx-certs.nix
  ];

  home = {
    username = "1146146";
    homeDirectory = "/home/1146146";

    packages = with pkgs; [
      lsof
      libiconv
    ];

    shellAliases = {
      nrs = "sudo nixos-rebuild switch --flake ~/.config/nix#EC1414438";
      hms = "home-manager switch --flake ~/.config/nix#1146146@EC1414438";
    };
  };

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
      export JAVAX_NET_SSL_TRUSTSTORE="${rtxCerts.trustStore}"
    '';
  };

  programs.git.extraConfig = {
    user.email = "ian.pascoe@rtx.com";
    user.name = "Ian Pascoe";
    credential = {
      helper = "manager";
      credentialStore = "cache";
      "https://github.com".username = "ian-pascoe";
      "https://github-us.utc.com".username = "e21146146";
    };
  };

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
      "systemProp.javax.net.ssl.trustStore" = "${rtxCerts.trustStore}";
      "systemProp.http.connectionTimeout" = "120000";
      "systemProp.http.socketTimeout" = "120000";
      "systemProp.https.connectionTimeout" = "120000";
      "systemProp.https.socketTimeout" = "120000";
    };
  };
}
