{
  lib,
  customLib,
  pkgs,
  username,
  ...
}:
{
  imports = lib.flatten [
    (customLib.findModules ../../modules/common)
    (customLib.findModules ../../modules/nixos)
    (customLib.findModules ../../modules/wsl)
    (customLib.findModules ../../modules/rtx)
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
