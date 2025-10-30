{ pkgs, ... }:
{
  home.packages = with pkgs; [
    uutils-coreutils-noprefix # GNU coreutils, written in Rust
    lsof # List open files
    openssl

    # Development tools
    nodejs_24
    go
    python313
    rustc
    cargo
    lua5_4
    gcc
    gnumake

    # Nix LSP and formatting tools
    nil
    nixfmt
    nixfmt-tree
    statix

    # Some other fun ones
    pipes-sh
  ];
}
