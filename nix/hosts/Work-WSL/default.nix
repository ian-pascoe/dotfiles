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

  wsl.enable = true;

  wsl.defaultUser = username;
  users.users = {
    "${username}" = {
      isNormalUser = true;
      extraGroups = [
        "wheel"
        "docker"
      ];
      shell = pkgs.zsh;
    };
  };
}
