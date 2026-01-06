{ pkgs, lib, ... }:
{
  programs.awscli = {
    enable = lib.mkDefault true;
    # unstable package updates and breaks too often
    package = lib.mkDefault pkgs.stable.awscli2;
  };
}
