{ pkgs, ... }:
{
  home.packages = with pkgs; [
    lua5_4
    lua-language-server
    selene
    stylua

    # luau
    luau
    luau-lsp
  ];
}
