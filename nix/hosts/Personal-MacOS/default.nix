{
  lib,
  customLib,
  pkgs,
  username,
  ...
}:
{
  imports = lib.flatten [
    (customLib.findModules ../../modules/common)
    (customLib.findModules ../../modules/darwin)
  ];

  nixpkgs.hostPlatform = "aarch64-darwin";

  system.primaryUser = "${username}";
  users.users."${username}" = {
    name = "${username}";
    home = "/Users/${username}";
    shell = pkgs.zsh;
  };
}
