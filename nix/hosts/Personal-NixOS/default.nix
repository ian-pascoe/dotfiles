{
  lib,
  pkgs,
  username,
  ...
}:
{
  imports = lib.flatten [
    (lib.module.findModules ../../modules/common)
    (lib.module.findModules ../../modules/nixos)
  ];

  networking.hostName = "Personal-NixOS";

  nixpkgs.hostPlatform = "x86_64-linux";

  users.users.${username} = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "docker"
    ];
    shell = pkgs.zsh;
  };
}
