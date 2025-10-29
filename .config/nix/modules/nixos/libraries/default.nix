{
  pkgs,
  lib,
  ...
}:
let
  libs = with pkgs; [
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
    LIBRARY_PATH = lib.mkAfter (lib.makeSearchPath "lib" libs);
    CPATH = lib.mkAfter (lib.makeSearchPath "include" devLibs);
  };
}
