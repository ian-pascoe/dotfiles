{
  lib,
  pkgs,
  username,
  ...
}:
{
  imports = lib.flatten [
    (lib.findModules ../../modules/common)
    (lib.findModules ../../modules/nixos)
    (lib.findModules ../../modules/wsl)
    (lib.findModules ../../modules/rtx)
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
