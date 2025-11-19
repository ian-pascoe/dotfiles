{
  description = "Ian's Nix Config";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.05";

    # NUR
    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # WSL
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Home manager
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Darwin
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Mac App Util
    mac-app-util.url = "github:hraban/mac-app-util";

    # Homebrew
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
    # Declarative tap management
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-stable,
      nur,
      nixos-wsl,
      home-manager,
      nix-darwin,
      mac-app-util,
      nix-homebrew,
      homebrew-core,
      homebrew-cask,
      ...
    }@inputs:
    let
      username =
        let
          envUser = builtins.getEnv "NIX_DEFAULT_USER";
        in
        if envUser != "" then envUser else "nixuser";

      # Custom library
      lib = nixpkgs.lib.extend (self: super: import ./lib { lib = self; } // home-manager.lib);

      # Common variables
      commonArgs = {
        inherit inputs username lib;
      };

      stableOverlay = final: prev: {
        stable = import nixpkgs-stable {
          inherit (final) system;
          config.allowUnfree = true;
        };
      };

      # Helper functions
      mkNixosSystem =
        modules:
        nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = commonArgs;
          modules = modules ++ [
            {
              nixpkgs.overlays = [
                stableOverlay
              ];
            }
          ];
        };

      mkDarwinSystem =
        modules:
        nix-darwin.lib.darwinSystem {
          system = "aarch64-darwin";
          specialArgs = commonArgs;
          modules = modules ++ [
            {
              nixpkgs.overlays = [
                stableOverlay
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
        home-manager.extraSpecialArgs = commonArgs;
        home-manager.users.${username} = import config;
      };

      mkHomebrewConfig = {
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
    in
    {
      # NixOS configuration entrypoint
      # Available through 'nixos-rebuild switch --flake .#Work-WSL'
      nixosConfigurations = {
        Work-WSL = mkNixosSystem [
          nixos-wsl.nixosModules.wsl
          nur.modules.nixos.default
          ./hosts/Work-WSL
          home-manager.nixosModules.home-manager
          (mkHomeManagerConfig ./homes/${"user@Work-WSL"})
        ];
      };

      # Darwin configuration entrypoint
      # Available through 'darwin-rebuild switch --flake .#Personal-MacOS'
      darwinConfigurations = {
        Personal-MacOS = mkDarwinSystem [
          nur.modules.darwin.default
          mac-app-util.darwinModules.default
          nix-homebrew.darwinModules.nix-homebrew
          mkHomebrewConfig
          ./hosts/Personal-MacOS
          home-manager.darwinModules.home-manager
          {
            home-manager.sharedModules = [
              mac-app-util.homeManagerModules.default
            ];
          }
          (mkHomeManagerConfig ./homes/${"user@Personal-MacOS"})
        ];
      };
    };
}
