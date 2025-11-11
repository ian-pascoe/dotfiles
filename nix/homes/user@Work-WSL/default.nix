{ config, username, ... }:
{
  imports = [
    ../../modules/common/home
    ../../modules/nixos/home
    ../../modules/wsl/home
    ../../modules/rtx/home
  ];

  home = {
    inherit username;
    homeDirectory = "/home/${username}";

    shellAliases = {
      nrs = "sudo -HE nixos-rebuild switch --flake ${config.home.homeDirectory}/.nix#Work-WSL --impure";
    };
  };
}
