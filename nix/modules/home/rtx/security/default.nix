{ pkgs, lib, ... }:
let
  rtxCerts = lib.rtx.genCerts { inherit pkgs; };
in
{
  _module.args = {
    inherit rtxCerts;
  };
}
