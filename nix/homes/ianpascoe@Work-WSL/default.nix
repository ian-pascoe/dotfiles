{ config, ... }:
{
  imports = [
    ../../modules/common/home
    ../../modules/nixos/home
    ../../modules/wsl/home
    ../../modules/rtx/home
  ];

  home = {
    username = "ianpascoe";
    homeDirectory = "/home/ianpascoe";

    shellAliases = {
      nrs = "sudo -HE nixos-rebuild switch --flake ${config.home.homeDirectory}/.nix#Work-WSL --impure";
    };
  };
}
