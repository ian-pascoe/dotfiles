{pkgs, ...}: {
  imports = [
    ../../modules/common/nix
    ../../modules/common/programs
    ../../modules/darwin/libraries
    ../../modules/darwin/homebrew
  ];

  nixpkgs.hostPlatform = "aarch64-darwin";

  system = {
    primaryUser = "ianpascoe";
    defaults = {
      dock = {
        autohide = true;
        persistent-apps = [
          {
            app = "/System/Applications/System Settings.app";
          }
          {
            app = "/System/Applications/Launchpad.app";
          }
          {
            spacer = {small = true;};
          }
          {
            app = "/Applications/Google Chrome.app";
          }
          {
            app = "/System/Applications/Messages.app";
          }
          {
            app = "/System/Applications/FaceTime.app";
          }
          {
            app = "/Applications/Ghostty.app";
          }
          {
            app = "/System/Applications/Notes.app";
          }
        ];
      };
    };
  };

  users.users.ianpascoe = {
    name = "ianpascoe";
    home = "/Users/ianpascoe";
    shell = pkgs.zsh;
  };

  # $ darwin-rebuild changelog
  system.stateVersion = 6;
}
