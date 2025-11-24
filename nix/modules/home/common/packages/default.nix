{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # Core utilities
    coreutils
    lsof
    openssl

    # Development tools
    go
    python315
    lua5_4
    gcc
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
