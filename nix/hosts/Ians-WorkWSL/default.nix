{
  lib,
  pkgs,
  ...
}:
let
  primaryUser = "ianpascoe";
in
{
  imports = lib.flatten [
    (lib.module.findModules ../../modules/common)
    (lib.module.findModules ../../modules/nixos)
    (lib.module.findModules ../../modules/wsl)
    (lib.module.findModules ../../modules/rtx)
  ];

  networking.hostName = "Work-WSL";

  nixpkgs.hostPlatform = "x86_64-linux";

  wsl.enable = true;

  wsl.defaultUser = primaryUser;
  users.users.${primaryUser} = {
    isNormalUser = true;
    name = "${primaryUser}";
    home = "/home/${primaryUser}";
    extraGroups = [
      "wheel"
      "docker"
    ];
    shell = pkgs.zsh;
  };
}
