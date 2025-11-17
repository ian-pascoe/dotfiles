{
  pkgs,
  ...
}:
{
  security = {
    pki.installCACerts = true;
    pki.certificateFiles = [
      "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
    ];
  };

  environment.variables = {
    NIX_SSL_CERT_FILE = builtins.getEnv "NIX_SSL_CERT_FILE";
  };
}
