{pkgs, ...}: {
  home.packages = with pkgs; [
    git-credential-manager
  ];
  programs.git = {
    enable = true;
    package = pkgs.gitFull;
    lfs.enable = true;
    extraConfig = {
      user.email = "ian.pascoe@rtx.com";
      user.name = "Ian Pascoe";
      credential = {
        helper = "manager";
        credentialStore = "plaintext";
        "https://github.com".username = "ian-pascoe";
        "https://github.com".provider = "github";
        "https://github-us.utc.com".username = "e21146146";
        "https://github-us.utc.com".provider = "github";
      };
    };
  };
}
