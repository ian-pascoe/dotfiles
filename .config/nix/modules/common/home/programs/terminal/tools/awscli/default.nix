{ pkgs, ... }:
{
  programs.awscli = {
    enable = true;
    package = pkgs.awscli2.override { doCheck = false; }; # The tests on this take forever
  };
}
