{
  lib,
  ...
}:
{
  programs.git = lib.mkDefault {
    enable = true;
    lfs.enable = true;
    settings = {
      user.email = "ian.g.pascoe@gmail.com";
      user.name = "Ian Pascoe";
    };
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
