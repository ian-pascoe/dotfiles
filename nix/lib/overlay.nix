{ inputs, ... }:
let
  inherit (inputs) nixpkgs-stable;
in
{
  mkStableOverlay = final: prev: {
    stable = import nixpkgs-stable {
      inherit (final) system;
      config.allowUnfree = true;
    };
  };
}
