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
      attr
      acl
      systemd
      libiconv
      icu
    ];
  devLibs = map (pkg: pkg.dev or pkg) libs;
in
{
  environment.systemPackages = libs;

  environment.variables = {
    LIBRARY_PATH = lib.makeSearchPath "lib" libs;
    CPATH = lib.makeSearchPath "include" devLibs;
  };
}
