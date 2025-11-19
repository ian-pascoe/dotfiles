{
  lib,
  customLib,
  config,
  username,
  ...
}:
{
  imports = lib.flatten [
    (customLib.findModules ../../modules/home/common)
    (customLib.findModules ../../modules/home/nixos)
    (customLib.findModules ../../modules/home/wsl)
    (customLib.findModules ../../modules/home/rtx)
  ];

  home = {
    inherit username;
    homeDirectory = "/home/${username}";

    shellAliases = {
      nrs = "sudo -HE nixos-rebuild switch --flake ${config.home.homeDirectory}/.nix#Work-WSL --impure";
    };
  };
}
