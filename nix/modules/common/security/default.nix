{
  pkgs,
  ...
}:
let
  certificateFiles =
    let
      envCerts = builtins.getEnv "NIX_SSL_CERT_FILE";
    in
    if envCerts != "" then
      [
        "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
        envCerts
      ]
    else
      [
        "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
      ];
in
{
  security = {
    pki.installCACerts = true;
    pki.certificateFiles = certificateFiles;
  };

  environment.variables = {
    NIX_SSL_CERT_FILE = builtins.getEnv "NIX_SSL_CERT_FILE";
    SSL_CERT_FILE = "/etc/ssl/certs/ca-bundle.crt";
    SSL_CERT_DIR = "/etc/ssl/certs";
    REQUESTS_CA_BUNDLE = "/etc/ssl/certs/ca-bundle.crt";
  };
}
