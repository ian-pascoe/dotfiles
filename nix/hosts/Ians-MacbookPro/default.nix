{
  lib,
  pkgs,
  ...
}:
let
  primaryUser = "ianpascoe";
in
{
  imports = lib.flatten [
    (lib.module.findModules ../../modules/common)
    (lib.module.findModules ../../modules/darwin)
  ];

  nixpkgs.hostPlatform = "aarch64-darwin";

  system = {
    inherit primaryUser;
  };
  users.users.${primaryUser} = {
    name = "${primaryUser}";
    home = "/Users/${primaryUser}";
    shell = pkgs.zsh;
  };
}
