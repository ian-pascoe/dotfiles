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
    (lib.module.findModules ../../modules/wsl)
    (lib.module.findModules ../../modules/rtx)
  ];

  networking.hostName = "Work-WSL";

  nixpkgs.hostPlatform = "x86_64-linux";

  wsl.enable = true;

  wsl.defaultUser = username;
  users.users.${username} = {
    isNormalUser = true;
    name = "${username}";
    home = "/home/${username}";
    extraGroups = [
      "wheel"
      "docker"
    ];
    shell = pkgs.zsh;
  };
}
