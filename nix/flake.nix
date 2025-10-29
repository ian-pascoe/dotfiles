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

    # Index Database
    nix-index-database = {
      url = "github:nix-community/nix-index-database/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # WSL
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Home manager
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Darwin
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
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
      nix-index-database,
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
      inherit (self) outputs;

      # Common variables
      commonArgs = { inherit inputs outputs; };

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

      mkHomeManagerConfig = user: config: {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          backupFileExtension = "backup";
        };
        home-manager.extraSpecialArgs = commonArgs;
        home-manager.users.${user} = import config;
      };

      mkHomebrewConfig = user: {
        nix-homebrew = {
          enable = true;
          enableRosetta = true;
          inherit user;
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
      # Available through 'nixos-rebuild switch --flake .#EC1414438'
      nixosConfigurations = {
        EC1414438 = mkNixosSystem [
          nixos-wsl.nixosModules.wsl
          nur.modules.nixos.default
          nix-index-database.nixosModules.nix-index
          { programs.nix-index-database.comma.enable = true; }
          ./hosts/EC1414438
          home-manager.nixosModules.home-manager
          (mkHomeManagerConfig "e21146146" ./homes/${"e21146146@EC1414438"})
        ];
      };

      # Darwin configuration entrypoint
      # Available through 'darwin-rebuild switch --flake .#Ians-Macbook-Pro'
      darwinConfigurations = {
        "Ians-Macbook-Pro" = mkDarwinSystem [
          nur.modules.darwin.default
          nix-index-database.darwinModules.nix-index
          { programs.nix-index-database.comma.enable = true; }
          mac-app-util.darwinModules.default
          nix-homebrew.darwinModules.nix-homebrew
          (mkHomebrewConfig "ianpascoe")
          ./hosts/Ians-Macbook-Pro
          home-manager.darwinModules.home-manager
          {
            home-manager.sharedModules = [
              mac-app-util.homeManagerModules.default
            ];
          }
          (mkHomeManagerConfig "ianpascoe" ./homes/${"ianpascoe@Ians-Macbook-Pro"})
        ];
      };
    };
}
