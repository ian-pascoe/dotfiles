{rtxCerts, ...}: let
in {
  imports = [
    ../../modules/common/home
    ../../modules/nixos/home
    ../../modules/util/rtx/certs
  ];

  home = {
    username = "e21146146";
    homeDirectory = "/home/e21146146";

    shellAliases = {
      nrs = "sudo nixos-rebuild switch --flake ~/.config/nix#EC1414438";
      nfu = "nix flake update --flake ~/.config/nix";
    };

    sessionVariables = {
      AWS_PROFILE = "saml";
      AWS_CA_BUNDLE = "/etc/ssl/certs/ca-certificates.crt";
    };
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
}
