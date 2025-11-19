{
  pkgs,
  lib,
  ...
}:
let
  rtxCerts = lib.rtx.genCerts { inherit pkgs; };
in
{
  security = {
    pki.certificateFiles = [
      "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
    ]
    ++ rtxCerts.pemFiles;
  };

  _module.args = {
    inherit rtxCerts;
  };
}
