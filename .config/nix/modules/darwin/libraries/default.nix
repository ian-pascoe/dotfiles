{
  pkgs,
  lib,
  ...
}: let
  libraryPath = lib.makeLibraryPath [
    pkgs.libiconv
    pkgs.icu
  ];
in {
  environment.sessionVariables = {
    LIBRARY_PATH = ''${libraryPath}''${LIBRARY_PATH:+:$LIBRARY_PATH}'';
  };
}
