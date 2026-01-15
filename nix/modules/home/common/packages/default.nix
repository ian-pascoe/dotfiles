{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # core utils
    coreutils
    lsof
    openssl

    # c
    clang

    # markdown
    markdownlint-cli2

    # toml
    taplo

    # nix
    nil
    nixfmt
    nixfmt-tree
    statix

    # build systems
    gnumake
    cmake
    ninja

    # other
    mise
    pipes
  ];
}
