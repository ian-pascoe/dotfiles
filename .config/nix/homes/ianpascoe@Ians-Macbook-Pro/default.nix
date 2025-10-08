{
  imports = [
    ../../modules/common/home
    ../../modules/darwin/home
  ];

  home = {
    shellAliases = {
      nds = "sudo nix run nix-darwin/master#darwin-rebuild -- switch --flake ~/.config/nix#Ians-Macbook-Pro";
    };
  };
}
