{ pkgs, ... }:
{
  home.packages = with pkgs; [
    uutils-coreutils # GNU coreutils, written in Rust
    lsof # List open files
    nodejs_24
    go
    python313
    rustc
    cargo
    lua5_4
    gcc
    gnumake
    nil
    nixfmt
    nixfmt-tree
  ];
}
