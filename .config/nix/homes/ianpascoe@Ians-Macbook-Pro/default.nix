{
  imports = [
    ../../modules/common/home
    ../../modules/darwin/home
  ];

  home = {
    shellAliases = {
      nds = "sudo -HE nix run nix-darwin/master#darwin-rebuild -- switch --flake /Users/ianpascoe/.config/nix#Ians-Macbook-Pro --impure";
    };
  };
}
