# This is your system's configuration file.
# Use this to configure your system environment (it replaces /etc/nixos/configuration.nix)
{ pkgs, ... }:
{
  imports = [
    ../../modules/common
    ../../modules/nixos
    ../../modules/wsl
    ../../modules/rtx
  ];

  networking.hostName = "EC1414438";

  users.users = {
    "e21146146" = {
      isNormalUser = true;
      extraGroups = [
        "wheel"
        "docker"
      ];
      shell = pkgs.zsh;
    };
  };
  wsl.defaultUser = "e21146146";
}
