{
  pkgs,
  lib,
  ...
}:
{
  programs.git = lib.mkDefault {
    enable = true;
    package = pkgs.gitFull;
    lfs.enable = true;
    extraConfig = {
      user.email = "ian.g.pascoe@gmail.com";
      user.name = "Ian Pascoe";
      credential = {
        "https://github.com".username = "ian-pascoe";
      };
    };
  };
  programs.gh = {
    enable = true;
    gitCredentialHelper = {
      enable = true;
    };
  };
}
