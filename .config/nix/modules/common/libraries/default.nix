{
  pkgs,
  lib,
  ...
}:
let
  libs = with pkgs; [
    # List by default
    zlib
    zstd
    stdenv.cc.cc
    curl
    openssl
    libssh
    bzip2
    libxml2
    libsodium
    util-linux
    xz

    # Required
    glib
    gtk2

    # Others I need
    icu
    readline
    ncurses
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
