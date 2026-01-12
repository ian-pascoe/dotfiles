{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # core utils
    coreutils
    lsof
    openssl

    # c
    clang
    gnumake

    # markdown
    markdownlint-cli2

    # toml
    taplo

    # nix
    nil
    nixfmt
    nixfmt-tree
    statix

    # other
    mise
    pipes
  ];
}
