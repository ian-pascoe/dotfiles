{
  pkgs,
  rtxCerts,
  ...
}:
{
  imports = [
    ../../util/rtx/certs
  ];
  security = {
    pki.installCACerts = true;
    pki.certificateFiles = [
      "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
    ]
    ++ rtxCerts.pemFiles;
  };

  environment = {
    sessionVariables = {
      # SSL certificate settings
      SSL_CERT_FILE = "/etc/ssl/certs/ca-bundle.crt";
      SSL_CERT_DIR = "/etc/ssl/certs";
      REQUESTS_CA_BUNDLE = "/etc/ssl/certs/ca-bundle.crt";

      # Java specific
      JDK_JAVA_OPTIONS = "-Djavax.net.ssl.trustStore=${rtxCerts.trustStore}";
      JAVA_TOOL_OPTIONS = "-Djavax.net.ssl.trustStore=${rtxCerts.trustStore}";
      JAVA_OPTS = "-Djavax.net.ssl.trustStore=${rtxCerts.trustStore}";
      JAVA_OPTIONS = "-Djavax.net.ssl.trustStore=${rtxCerts.trustStore}";

      # Node Specific
      NODE_EXTRA_CA_CERTS = "/etc/ssl/certs/ca-bundle.crt";
      NODE_USE_SYSTEM_CA = "1";
    };
  };
}
