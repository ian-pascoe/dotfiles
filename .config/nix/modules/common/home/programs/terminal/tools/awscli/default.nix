{ pkgs, ... }:
{
  programs.awscli = {
    enable = true;
    package = pkgs.awscli2.overrideAttrs (oldAttrs: {
      doCheck = false;
    }); # The tests on this take forever
  };
}
