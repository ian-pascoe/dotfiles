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
  environment.systemPackages = libs;

  environment.variables = {
    APPLE_SDK_PATH = "${pkgs.apple-sdk_26}";
    LIBRARY_PATH = lib.makeSearchPath "lib" libs;
    CPATH = lib.makeSearchPath "include" devLibs;
  };
}
