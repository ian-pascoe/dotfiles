{ lib, ... }:
let
  compress = ''
    compress() { tar -czf "''${1%/}.tar.gz" "''${1%/}"; }
  '';
in
{
  programs = {
    bash.initExtra = compress;
    zsh.initContent = lib.mkOrder 1000 compress;
  };

  home.shellAliases = {
    decompress = "tar -xzf";
  };
}
