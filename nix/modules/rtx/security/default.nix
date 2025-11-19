{
  pkgs,
  customLib,
  ...
}:
{
  security = {
    pki.certificateFiles = [
      "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
    ]
    ++ customLib.rtx.certs.pemFiles;
  };
}
