{
  inputs,
  lib,
  ...
}:
let
  inherit (inputs) homebrew-core homebrew-cask;
  username =
    let
      envUser = builtins.getEnv "NIX_DEFAULT_USER";
    in
    if envUser != "" then envUser else "nixuser";
  specialArgs = {
    inherit inputs lib username;
  };
in
{
  inherit username;

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

  mkHomeManagerConfig = config: {
    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      backupFileExtension = "backup";
    };
    home-manager.extraSpecialArgs = specialArgs;
    home-manager.users.${username} = import config;
  };

  mkHomebrewConfig = _: {
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
