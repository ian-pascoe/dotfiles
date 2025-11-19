{ pkgs, customLib, ... }:
let
  rtxCerts = customLib.rtx.genCerts { inherit pkgs; };
in
{
  _module.args = {
    inherit rtxCerts;
  };
}
