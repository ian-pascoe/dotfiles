{
  lib,
  config,
  username,
  ...
}:
{
  imports = lib.flatten [
    (lib.findModules ../../modules/home/common)
    (lib.findModules ../../modules/home/nixos)
    (lib.findModules ../../modules/home/wsl)
    (lib.findModules ../../modules/home/rtx)
  ];

  home = {
    inherit username;
    homeDirectory = "/home/${username}";

    shellAliases = {
      nrs = "sudo -HE nixos-rebuild switch --flake ${config.home.homeDirectory}/.nix#Work-WSL --impure";
    };
  };
}
