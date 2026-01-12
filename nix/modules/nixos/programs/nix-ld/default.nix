{ pkgs, lib, ... }:
{
  programs.nix-ld = {
    enable = lib.mkDefault true;
    libraries = with pkgs; [
      # List by default
      zlib
      zstd
      stdenv.cc.cc
      glibc
      curl
      openssl
      attr
      libssh
      bzip2
      libxml2
      acl
      libsodium
      util-linux
      xz
      systemd

      # Required
      glib
      gtk2

      # Some more libraries that I needed to run programs
      libiconv
      icu
      readline
      ncurses
    ];
  };
}
