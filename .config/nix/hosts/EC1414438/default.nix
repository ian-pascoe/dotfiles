# This is your system's configuration file.
# Use this to configure your system environment (it replaces /etc/nixos/configuration.nix)
{
  pkgs,
  rtxCerts,
  ...
}: {
  imports = [
    ../../modules/common/nix
    ../../modules/nixos/programs
    ../../modules/nixos/services
    ../../modules/util/rtx/certs
  ];

  wsl.enable = true;

  security = {
    pki.installCACerts = true;
    pki.certificateFiles =
      [
        "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
      ]
      ++ rtxCerts.pemFiles;
  };

  networking = {
    hostName = "EC1414438";
    proxy.default = "http://REDACTED:80/";
    proxy.noProxy = "localhost,127.0.0.1,.raytheon.com,.ray.com,.rtx.com,.utc.com,.adxrt.com,.registry.npmjs.org,.eks.amazonaws.com";
  };

  environment = {
    sessionVariables = {
      http_proxy = "http://REDACTED:80/";
      https_proxy = "http://REDACTED:80/";
      HTTP_PROXY = "http://REDACTED:80/";
      HTTPS_PROXY = "http://REDACTED:80/";
      all_proxy = "http://REDACTED:80/";
      ALL_PROXY = "http://REDACTED:80/";
      no_proxy = "localhost,127.0.0.1,.raytheon.com,.ray.com,.rtx.com,.utc.com,.adxrt.com,.registry.npmjs.org,.eks.amazonaws.com";
      NO_PROXY = "localhost,127.0.0.1,.raytheon.com,.ray.com,.rtx.com,.utc.com,.adxrt.com,.registry.npmjs.org,.eks.amazonaws.com";

      # Used by lemminx
      HTTP_PROXY_HOST = "REDACTED";
      HTTP_PROXY_PORT = "80";

      # SSL certificate settings
      SSL_CERT_FILE = "/etc/ssl/certs/ca-certificates.crt";
      SSL_CERT_DIR = "/etc/ssl/certs";
      REQUESTS_CA_BUNDLE = "/etc/ssl/certs/ca-certificates.crt";
      # Java specific
      JDK_JAVA_OPTIONS = "-Djavax.net.ssl.trustStore=${rtxCerts.trustStore}";
      JAVA_TOOL_OPTIONS = "-Djavax.net.ssl.trustStore=${rtxCerts.trustStore}";
      JAVA_OPTS = "-Djavax.net.ssl.trustStore=${rtxCerts.trustStore}";
      JAVA_OPTIONS = "-Djavax.net.ssl.trustStore=${rtxCerts.trustStore}";
    };
  };

  users.users = {
    "e21146146" = {
      isNormalUser = true;
      extraGroups = ["wheel" "docker"];
      shell = pkgs.zsh;
      ignoreShellProgramCheck = true;
    };
  };
  wsl.defaultUser = "e21146146";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "25.05";
}
