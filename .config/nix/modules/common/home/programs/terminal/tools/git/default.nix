{
  lib,
  ...
}:
{
  programs.git = lib.mkDefault {
    enable = true;
    lfs.enable = true;
    userEmail = "ian.g.pascoe@gmail.com";
    userName = "Ian Pascoe";
  };

  programs.gh = lib.mkDefault {
    enable = true;
    gitCredentialHelper = {
      enable = true;
      hosts = [
        "https://github.com"
        "https://gist.github.com"
      ];
    };
    settings = {
      git_protocol = "https";
    };
  };
}
