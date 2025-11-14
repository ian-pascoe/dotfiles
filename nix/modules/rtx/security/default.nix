{
  lib,
  rtxCerts,
  ...
}:
{
  imports = [
    ../../util/rtx/certs
  ];

  security = {
    pki.certificateFiles = lib.mkAfter rtxCerts.pemFiles;
  };
}
