{
  pkgs,
  lib,
  ...
}:
{
  home.packages = with pkgs; [
    git-credential-manager
  ];
  programs.git = lib.mkDefault {
    enable = true;
    package = pkgs.gitFull;
    lfs.enable = true;
    extraConfig = {
      user.email = "ian.g.pascoe@gmail.com";
      user.name = "Ian Pascoe";
      credential = {
        helper = "manager";
        credentialStore = "plaintext";
        "https://github.com".username = "ian-pascoe";
      };
    };
  };
}
