{
  lib,
  ...
}:
{
  programs.git = {
    enable = lib.mkDefault true;
    lfs.enable = lib.mkDefault true;
    maintenance.enable = lib.mkDefault true;
    settings = {
      alias = {
        co = "checkout";
        br = "branch";
        ci = "commit";
        st = "status";
      };
      branch = {
        sort = "-committerdate"; # Show most recently updated branches first
      };
      core = {
        autocrlf = false; # Disable automatic line ending conversion
        ignorecase = false; # Case-sensitive filenames
      };
      column = {
        ui = "auto"; # Enable columnar output where supported
      };
      commit = {
        verbose = true; # Show diff in commit message editor
      };
      diff = {
        algorithm = "histogram"; # Clearer diffs on moved/edited lines
        colorMoved = "plain"; # Highlight moved blocks in diffs
        mnemonicPrefix = true; # More intuitive refs in diff output
      };
      fetch = {
        prune = true;
      };
      init = {
        defaultBranch = "master"; # Use 'master' as the default branch name
      };
      pull = {
        rebase = true; # Use rebase by default when pulling
      };
      push = {
        autoSetupRemote = true; # Automatically set upstream on first push
      };
      rerere = {
        enabled = true; # Enable reuse of recorded conflict resolutions
        autoupdate = true; # Automatically update resolutions when possible
      };
      tag = {
        sort = "-version:refname"; # Show most recent tags first
      };
      user = {
        email = lib.mkDefault "ian.g.pascoe@gmail.com";
        name = lib.mkDefault "Ian Pascoe";
      };
    };
  };

  programs.gh = {
    enable = lib.mkDefault true;
    gitCredentialHelper = {
      enable = lib.mkDefault true;
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
