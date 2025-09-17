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
}
