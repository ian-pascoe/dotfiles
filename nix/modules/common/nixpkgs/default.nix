{ lib, ... }:
{
  nixpkgs = {
    config = {
      allowUnfree = lib.mkDefault true;
      allowUnfreePredicate = lib.mkDefault (_: true);
      allowUnsupportedSystem = lib.mkDefault true;
    };
  };
}
