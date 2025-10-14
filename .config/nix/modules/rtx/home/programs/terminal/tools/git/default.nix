{
  programs.git = {
    enable = true;
    lfs.enable = true;
    userEmail = "ian.pascoe@rtx.com";
    userName = "Ian Pascoe";
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
