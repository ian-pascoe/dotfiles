{
  pkgs,
  lib,
  commonLibs,
  ...
}:
let
  libs =
    with pkgs;
    commonLibs
    ++ [
      darwin.libiconv
      darwin.ICU
    ];
  devLibs = map (pkg: pkg.dev or pkg) libs;
in
{
  imports = [
    ../../util/libraries
  ];

  environment.systemPackages = libs;

  environment.variables = {
    LIBRARY_PATH = lib.makeSearchPath "lib" libs;
    CPATH = lib.makeSearchPath "include" devLibs;
  };
}
