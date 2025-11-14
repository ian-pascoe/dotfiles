# This is your system's configuration file.
# Use this to configure your system environment (it replaces /etc/nixos/configuration.nix)
{ pkgs, username, ... }:
{
  imports = [
    ../../modules/common
    ../../modules/nixos
    ../../modules/wsl
    ../../modules/rtx
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
