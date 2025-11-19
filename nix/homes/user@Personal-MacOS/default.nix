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
    (customLib.findModules ../../modules/home/darwin)
  ];

  home = {
    inherit username;
    homeDirectory = "/Users/${username}";
    shellAliases = {
      nds = "sudo -HE nix run nix-darwin/master#darwin-rebuild -- switch --flake ${config.home.homeDirectory}/.nix#Personal-MacOS --impure";
    };
  };
}
