{
  pkgs,
  lib,
  ...
}:
let
  libs = with pkgs; [
    darwin.libiconv
    darwin.ICU
  ];
  devLibs = map (pkg: pkg.dev or pkg) libs;
in
{
  environment.systemPackages = libs;

  environment.variables = {
    LIBRARY_PATH = lib.mkAfter (lib.makeSearchPath "lib" libs);
    CPATH = lib.mkAfter (lib.makeSearchPath "include" devLibs);
  };
}
