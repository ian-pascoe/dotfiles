{ pkgs, ... }:
{
  _module.args.commonLibs = with pkgs; [
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
}
