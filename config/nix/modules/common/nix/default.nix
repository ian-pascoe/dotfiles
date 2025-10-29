{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:
{
  nix =
    let
      flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;
    in
    {
      gc.automatic = true;
      optimise.automatic = true;
      settings = {
        experimental-features = [
          "nix-command"
          "flakes"
        ];
        # Workaround for https://github.com/NixOS/nix/issues/9574
        nix-path = config.nix.nixPath;
      };

      # Opinionated: make flake registry and nix path match flake inputs
      registry = lib.mapAttrs (_: flake: { inherit flake; }) flakeInputs;
      nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;
    };

  nixpkgs = {
    config = {
      allowUnfree = true;
      allowUnfreePredicate = _: true;
    };
  };

  environment = {
    systemPackages = with pkgs; [
      curl
      wget
      unzip
      vim
      pkg-config
    ];
  };

  system = {
    configurationRevision = inputs.self.rev or inputs.self.dirtyRev or null;
  };

  fonts.packages = [ pkgs.nerd-fonts.jetbrains-mono ];
}
