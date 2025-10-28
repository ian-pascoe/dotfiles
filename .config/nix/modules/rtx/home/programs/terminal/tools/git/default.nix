{
  programs.git = {
    settings = {
      user.email = "ian.pascoe@rtx.com";
      user.name = "Ian Pascoe";
    };
  };

  programs.gh = {
    gitCredentialHelper = {
      hosts = [
        "https://github.com"
        "https://gist.github.com"
        "https://github-us.utc.com"
      ];
    };
  };
}
