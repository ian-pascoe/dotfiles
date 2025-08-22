{
  inputs,
  pkgs,
  ...
}: {
  nixpkgs = {
    hostPlatform = "aarch64-darwin";
    # Configure your nixpkgs instance
    config = {
      # Disable if you don't want unfree packages
      allowUnfree = true;
      # Workaround for https://github.com/nix-community/home-manager/issues/2942
      allowUnfreePredicate = _: true;
    };
  };

  nix.settings.experimental-features = "nix-command flakes";

  system = {
    primaryUser = "ianpascoe";
    configurationRevision = inputs.self.rev or inputs.self.dirtyRev or null;
    defaults = {
      dock = {
        autohide = true;
        persistent-apps = [
          {
            app = "/System/Applications/Launchpad.app";
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
        ];
      };
    };
  };

  programs.bash.enable = true;
  programs.zsh = {
    enable = true;
    enableAutosuggestions = true;
  };

  fonts.packages = [
    pkgs.nerd-fonts.jetbrains-mono
  ];

  homebrew = {
    enable = true;
    brews = [
      "mas"
    ];
    casks = [
      "ghostty@tip"
      "google-chrome"
      "raycast"
      "karabiner-elements"
    ];
    masApps = {
      WireGuard = 1451685025;
    };
    onActivation = {
      autoUpdate = true;
      cleanup = "zap";
      upgrade = true;
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
