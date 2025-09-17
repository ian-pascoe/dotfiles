{
  pkgs,
  rtxCerts,
  ...
}: {
  imports = [
    ../../util/rtx/certs
  ];
  security = {
    pki.installCACerts = true;
    pki.certificateFiles =
      [
        "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
      ]
      ++ rtxCerts.pemFiles;
  };

  environment = {
    sessionVariables = {
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
}
