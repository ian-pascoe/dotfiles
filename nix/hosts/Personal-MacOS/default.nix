{
  lib,
  pkgs,
  username,
  ...
}:
{
  imports = lib.flatten [
    (lib.module.findModules ../../modules/common)
    (lib.module.findModules ../../modules/darwin)
  ];

  nixpkgs.hostPlatform = "aarch64-darwin";

  system.primaryUser = "${username}";
  users.users.${username} = {
    name = "${username}";
    home = "/Users/${username}";
    shell = pkgs.zsh;
  };
}
