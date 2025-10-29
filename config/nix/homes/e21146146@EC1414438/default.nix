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
      nrs = "[ -f ~/nix-env.sh ] && source ~/nix-env.sh || echo 'nix-env.sh not found!'; sudo -HE nixos-rebuild switch --flake /home/e21146146/.config/nix#EC1414438 --impure";
    };
  };
}
