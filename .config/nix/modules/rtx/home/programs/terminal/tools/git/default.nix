{
  programs.git = {
    enable = true;
    lfs.enable = true;
    settings = {
      user.email = "ian.pascoe@rtx.com";
      user.name = "Ian Pascoe";
    };
  };

  programs.gh = {
    enable = true;
    gitCredentialHelper = {
      enable = true;
      hosts = [
        "https://github.com"
        "https://gist.github.com"
        "https://github-us.utc.com"
      ];
    };
    settings = {
      git_protocol = "https";
    };
  };
}
