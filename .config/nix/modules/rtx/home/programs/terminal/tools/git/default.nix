{
  programs.git = {
    enable = true;
    lfs.enable = true;
    extraConfig = {
      core.autocrlf = false;
      user.email = "ian.pascoe@rtx.com";
      user.name = "Ian Pascoe";
      credential = {
        "https://github.com".username = "ian-pascoe";
        "https://github.com".provider = "github";
        "https://github-us.utc.com".username = "e21146146";
        "https://github-us.utc.com".provider = "github";
      };
    };
  };
  programs.gh = {
    enable = true;
    gitCredentialHelper = {
      enable = true;
      hosts = [
        "https://github-us.utc.com"
      ];
    };
  };
}
