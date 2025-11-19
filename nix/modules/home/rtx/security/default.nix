{ pkgs, customLib, ... }:
{
  _module.args = {
    rtxCerts = customLib.rtx.genCerts { inherit pkgs; };
  };
}
