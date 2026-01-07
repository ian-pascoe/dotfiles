{
  pkgs,
  ...
}:
{
  security = {
    pki = {
      installCACerts = true;
      certificateFiles = [
        "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
      ];
    };
  };

  environment.variables = {
    NIX_SSL_CERT_FILE =
      let
        envCertFile = builtins.getEnv "NIX_SSL_CERT_FILE";
      in
      if envCertFile != "" then envCertFile else "/etc/ssl/certs/ca-certificates.crt";
    SSL_CERT_FILE = "/etc/ssl/certs/ca-certificates.crt";
    SSL_CERT_DIR = "/etc/ssl/certs/";
  };
}
