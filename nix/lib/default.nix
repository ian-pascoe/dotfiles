{ inputs, ... }:
let
  inherit (inputs) nix-darwin home-manager;
  inherit (inputs.nixpkgs) lib;
in
lib.extend (
  final: prev:
  let
    args = {
      inherit inputs;
      lib = final;
    };
  in
  {
    system = import ./system.nix args;
    overlay = import ./overlay.nix args;
    module = import ./module.nix args;
    rtx = import ./rtx.nix args;
  }
  // nix-darwin.lib
  // home-manager.lib
)
