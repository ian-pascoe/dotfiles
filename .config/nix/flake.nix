{
  description = "Ian's Nix Config";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # Index Database
    nix-index-database.url = "github:nix-community/nix-index-database/main";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";

    # WSL
    nixos-wsl.url = "github:nix-community/NixOS-WSL/main";
    nixos-wsl.inputs.nixpkgs.follows = "nixpkgs";

    # Home manager
    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Darwin
    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    # Homebrew
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
  };

  outputs = {
    self,
    nixpkgs,
    nix-index-database,
    nixos-wsl,
    home-manager,
    nix-darwin,
    nix-homebrew,
    ...
  } @ inputs: let
    inherit (self) outputs;

    # Common variables
    commonArgs = {inherit inputs outputs;};

    # Helper functions
    mkNixosSystem = modules:
      nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = commonArgs;
        inherit modules;
      };

    mkDarwinSystem = modules:
      nix-darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        specialArgs = commonArgs;
        inherit modules;
      };

    mkHomeManagerConfig = user: config: {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.backupFileExtension = "backup";
      home-manager.extraSpecialArgs = commonArgs;
      home-manager.users.${user} = import config;
    };

    mkHomebrewConfig = user: {
      nix-homebrew = {
        enable = true;
        enableRosetta = true;
        autoMigrate = true;
        inherit user;
      };
    };
  in {
    # NixOS configuration entrypoint
    # Available through 'nixos-rebuild switch --flake .#EC1414438'
    nixosConfigurations = {
      EC1414438 = mkNixosSystem [
        nixos-wsl.nixosModules.wsl
        ./hosts/nixos
        nix-index-database.nixosModules.nix-index
        {programs.nix-index-database.comma.enable = true;}
        home-manager.nixosModules.home-manager
        (mkHomeManagerConfig "e21146146" ./homes/${"e21146146@EC1414438"})
      ];
    };

    # Darwin configuration entrypoint
    # Available through 'darwin-rebuild switch --flake .#Ians-Macbook-Pro'
    darwinConfigurations = {
      "Ians-Macbook-Pro" = mkDarwinSystem [
        ./hosts/Ians-Macbook-Pro
        nix-index-database.darwinModules.nix-index
        {programs.nix-index-database.comma.enable = true;}
        nix-homebrew.darwinModules.nix-homebrew
        (mkHomebrewConfig "ianpascoe")
        home-manager.darwinModules.home-manager
        (mkHomeManagerConfig "ianpascoe" ./homes/${"ianpascoe@Ians-Macbook-Pro"})
      ];
    };
  };
}
