{
  pkgs,
  lib,
  commonLibraries,
  ...
}:
let
  libs =
    with pkgs;
    commonLibraries
    ++ [
      darwin.libiconv
      darwin.ICU
    ];
  devLibs = map (pkg: pkg.dev or pkg) libs;
in
{
  environment = {
    systemPackages = libs;

    variables = {
      LIBRARY_PATH = lib.makeSearchPath "lib" libs;
      CPATH = lib.makeSearchPath "include" devLibs;
    };
  };
}
