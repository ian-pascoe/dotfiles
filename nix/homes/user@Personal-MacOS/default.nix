{ config, username, ... }:
{
  imports = [
    ../../modules/common/home
    ../../modules/darwin/home
  ];

  home = {
    inherit username;
    homeDirectory = "/Users/${username}";
    shellAliases = {
      nds = "sudo -HE nix run nix-darwin/master#darwin-rebuild -- switch --flake ${config.home.homeDirectory}/.nix#Personal-MacOS --impure";
    };
  };
}
