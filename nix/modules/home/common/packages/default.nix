{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # Core utilities
    coreutils
    lsof
    openssl

    # Development tools
    go
    python314
    lua5_4
    clang
    cctools
    gnumake

    # Nix LSP and formatting tools
    nil
    nixfmt
    nixfmt-tree
    statix

    # Some other fun ones
    pipes
  ];
}
