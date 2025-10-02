{ pkgs, ... }:
{
  imports = [
    ../../modules/common
    ../../modules/darwin
  ];
  nixpkgs.hostPlatform = "aarch64-darwin";
  system.primaryUser = "ianpascoe";
  users.users.ianpascoe = {
    name = "ianpascoe";
    home = "/Users/ianpascoe";
    shell = pkgs.zsh;
  };
}
