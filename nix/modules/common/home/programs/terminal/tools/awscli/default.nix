{ pkgs, ... }:
{
  programs.awscli = {
    enable = true;
    # Tests on this are prone to fail
    package = pkgs.awscli2.overrideAttrs (old: {
      doCheck = false;
      doInstallCheck = false;
    });
  };
}
