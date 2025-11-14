{
  pkgs,
  rtxCerts,
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
  imports = [
    ../../util/rtx/certs
  ];

  security = {
    pki.certificateFiles = certificateFiles ++ rtxCerts.pemFiles;
  };
}
