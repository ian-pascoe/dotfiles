{
  imports = [
    ../../modules/common/home
    ../../modules/nixos/home
    ../../modules/wsl/home
    ../../modules/rtx/home
  ];

  home = {
    username = "e21146146";
    homeDirectory = "/home/e21146146";

    shellAliases = {
      nrs = "source ~/proxy.sh; sudo -E nixos-rebuild switch --flake ~/.config/nix#EC1414438 --impure";
      nfu = "nix flake update --flake ~/.config/nix";
      ncg = "sudo nix-collect-garbage -d";
    };
  };
}
