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

    # SOPS Nix
    sops-nix = {
      url = "github:Mic92/sops-nix";
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
      sops-nix,
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
      # Custom library
      lib = import ./lib { inherit inputs; };
    in
    {
      nixosConfigurations = {
        Ians-WorkWSL = lib.system.mkNixosSystem "x86_64-linux" [
          nixos-wsl.nixosModules.wsl
          nur.modules.nixos.default
          sops-nix.nixosModules.sops
          ./hosts/Ians-WorkWSL
          home-manager.nixosModules.home-manager
          (lib.system.mkHomeManagerConfig "ianpascoe" ./homes/${"ianpascoe@Ians-WorkWSL"})
        ];
        Junkyard = lib.system.mkNixosSystem "x86_64-linux" [
          nixos-wsl.nixosModules.wsl
          nur.modules.nixos.default
          sops-nix.nixosModules.sops
          ./hosts/Junkyard
          home-manager.nixosModules.home-manager
          (lib.system.mkHomeManagerConfig "ianpascoe" ./homes/${"ianpascoe@Junkyard"})
        ];
      };

      darwinConfigurations = {
        Ians-MacbookPro = lib.system.mkDarwinSystem "aarch64-darwin" [
          nur.modules.darwin.default
          sops-nix.darwinModules.sops
          mac-app-util.darwinModules.default
          nix-homebrew.darwinModules.nix-homebrew
          (lib.system.mkHomebrewConfig "ianpascoe")
          ./hosts/Ians-MacbookPro
          home-manager.darwinModules.home-manager
          {
            home-manager.sharedModules = [
              mac-app-util.homeManagerModules.default
            ];
          }
          (lib.system.mkHomeManagerConfig "ianpascoe" ./homes/${"ianpascoe@Ians-MacbookPro"})
        ];
      };
    };
}
