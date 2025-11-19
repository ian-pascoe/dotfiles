{
  lib,
  pkgs,
  username,
  ...
}:
{
  imports = lib.flatten [
    (lib.findModules ../../modules/common)
    (lib.findModules ../../modules/darwin)
  ];

  nixpkgs.hostPlatform = "aarch64-darwin";

  system.primaryUser = "${username}";
  users.users."${username}" = {
    name = "${username}";
    home = "/Users/${username}";
    shell = pkgs.zsh;
  };
}
