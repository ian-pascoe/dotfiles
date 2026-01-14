{
  inputs,
  lib,
  ...
}:
let
  inherit (inputs)
    rust-overlay
    homebrew-core
    homebrew-cask
    homebrew-beads
    homebrew-anomalyco
    homebrew-bun
    ;
  specialArgs = { inherit inputs lib; };
in
{
  mkNixosSystem =
    system: modules:
    lib.nixosSystem {
      inherit system;
      inherit specialArgs;
      modules = modules ++ [
        {
          nixpkgs.overlays = [
            lib.overlay.mkStableOverlay
            rust-overlay.overlays.default
          ];
        }
      ];
    };

  mkDarwinSystem =
    system: modules:
    lib.darwinSystem {
      inherit system;
      inherit specialArgs;
      modules = modules ++ [
        {
          nixpkgs.overlays = [
            lib.overlay.mkStableOverlay
            rust-overlay.overlays.default
          ];
        }
      ];
    };

  mkHomeManagerConfig = username: config: {
    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      backupFileExtension = "backup";
    };
    home-manager.extraSpecialArgs = specialArgs // {
      inherit username;
    };
    home-manager.users.${username} = import config;
  };

  mkHomebrewConfig = username: {
    nix-homebrew = {
      enable = true;
      enableRosetta = true;
      user = username;
      autoMigrate = true;
      taps = {
        "homebrew/homebrew-core" = homebrew-core;
        "homebrew/homebrew-cask" = homebrew-cask;
        "steveyegge/homebrew-beads" = homebrew-beads;
        "anomalyco/homebrew-tap" = homebrew-anomalyco;
        "oven-sh/homebrew-bun" = homebrew-bun;
      };
      mutableTaps = false;
    };
  };
}
