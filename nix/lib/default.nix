{ inputs, ... }:
{
  module = import ./module.nix { inherit inputs; };
  overlay = import ./overlay.nix { inherit inputs; };
  rtx = import ./rtx.nix;
}
