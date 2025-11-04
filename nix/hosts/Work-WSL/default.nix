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

  networking.hostName = "Work-WSL";

  users.users = {
    "ianpascoe" = {
      isNormalUser = true;
      extraGroups = [
        "wheel"
        "docker"
      ];
      shell = pkgs.zsh;
    };
  };
  wsl.defaultUser = "ianpascoe";
}
