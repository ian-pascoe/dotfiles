{
  lib,
  config,
  username,
  ...
}:
{
  imports = lib.flatten [
    (lib.module.findModules ../../modules/home/common)
    (lib.module.findModules ../../modules/home/darwin)
  ];

  home = {
    inherit username;
    homeDirectory = "/Users/${username}";
    shellAliases = {
      nds = "sudo -HE nix run nix-darwin/master#darwin-rebuild -- switch --flake ${config.home.homeDirectory}/.dotfiles/nix#Personal-MacOS --impure";
    };
  };
}
