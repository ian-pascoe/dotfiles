{ lib, ... }:
# Extend nixpkgs.lib with custom functions
lib.extend (
  final: prev: {
    # Import custom module helpers
    inherit (import ./modules.nix { lib = final; }) findModules;
    inherit (import ./rtx { lib = final; }) rtx;
  }
)
