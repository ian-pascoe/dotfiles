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
    pki.certificateFiles = [
      "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
    ]
    ++ rtxCerts.pemFiles;
  };
}
