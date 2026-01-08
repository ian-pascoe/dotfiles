{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # core utils
    coreutils
    lsof
    openssl

    # golang
    go

    # python
    python314

    # javascript
    prettier
    prettierd
    eslint
    eslint_d
    biome

    # lua
    lua5_4
    selene
    stylua

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
