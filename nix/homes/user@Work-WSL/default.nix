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
    (lib.module.findModules ../../modules/home/wsl)
    (lib.module.findModules ../../modules/home/rtx)
  ];

  home = {
    inherit username;
    homeDirectory = "/home/${username}";

    shellAliases = {
      nrs = "sudo -HE nixos-rebuild switch --flake ${config.home.homeDirectory}/.nix#Work-WSL --impure";
    };
  };
}
