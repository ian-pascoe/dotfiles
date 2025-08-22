# This is your system's configuration file.
# Use this to configure your system environment (it replaces /etc/nixos/configuration.nix)
{
  inputs,
  lib,
  config,
  pkgs,
  ...
}: {
  wsl.enable = true;

  nixpkgs = {
    config = {
      allowUnfree = true;
    };
  };

  nix = let
    flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;
  in {
    settings = {
      experimental-features = ["nix-command" "flakes"];
      # Workaround for https://github.com/NixOS/nix/issues/9574
      nix-path = config.nix.nixPath;
    };

    # Opinionated: make flake registry and nix path match flake inputs
    registry = lib.mapAttrs (_: flake: {inherit flake;}) flakeInputs;
    nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;
  };

  security = let
    certs = pkgs.fetchzip {
      url = "https://pki.rtx.com/certificate/RTX_Cert_Bundle-current.zip";
      sha256 = "sha256-4UqqonCQThHkt5dsq3FQJrUWP0D07mmlDdBjmTTlRmY=";
    };
    pemFiles =
      map (f: "${certs}/PEM/${f}")
      (builtins.filter (f: f != "." && f != ".." && f != "README.txt" && builtins.match ".+\\.cer$" f != null)
        (builtins.attrNames (builtins.readDir "${certs}/PEM")));
  in {
    pki.certificateFiles =
      [
        "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
      ]
      ++ pemFiles;
  };

  networking.hostName = "EC1414438";
  networking.proxy.default = "http://REDACTED:80/";
  networking.proxy.noProxy = "localhost,127.0.0.1,.raytheon.com,.ray.com,.rtx.com,.utc.com,.adxrt.com,.registry.npmjs.org,.eks.amazonaws.com";

  virtualisation.docker.enable = true;

  users.users = {
    "1146146" = {
      isNormalUser = true;
      extraGroups = ["wheel" "docker"];
      shell = pkgs.zsh;
    };
  };
  wsl.defaultUser = "1146146";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "25.05";
}
