{
  lib,
  config,
  username,
  ...
}:
{
  imports = lib.flatten [
    (lib.module.findModules ../../modules/home/common)
    (lib.module.findModules ../../modules/home/nixos)
  ];

  home = {
    inherit username;
    homeDirectory = "/home/${username}";

    shellAliases = {
      nrs = "sudo -HE nixos-rebuild switch --flake ${config.home.homeDirectory}/.dotfiles/nix#Personal-NixOS --impure";
    };
  };
}
