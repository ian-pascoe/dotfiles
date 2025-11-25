{
  inputs,
  lib,
  ...
}:
let
  inherit (inputs) homebrew-core homebrew-cask;
  specialArgs = {
    inherit inputs lib;
  };
in
{
  mkNixosSystem =
    modules:
    lib.nixosSystem {
      system = "x86_64-linux";
      inherit specialArgs;
      modules = modules ++ [
        {
          nixpkgs.overlays = [
            lib.overlay.mkStableOverlay
          ];
        }
      ];
    };

  mkDarwinSystem =
    modules:
    lib.darwinSystem {
      system = "aarch64-darwin";
      inherit specialArgs;
      modules = modules ++ [
        {
          nixpkgs.overlays = [
            lib.overlay.mkStableOverlay
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
    home-manager.extraSpecialArgs = specialArgs;
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
      };
      mutableTaps = false;
    };
  };
}
