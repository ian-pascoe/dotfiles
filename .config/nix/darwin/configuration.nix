{
  inputs,
  pkgs,
  ...
}: {
  imports = [../modules/nixpkgs-config.nix];

  nixpkgs.hostPlatform = "aarch64-darwin";

  nix.settings.experimental-features = "nix-command flakes";
  nix.gc.automatic = true;
  nix.optimise.automatic = true;

  system = {
    primaryUser = "ianpascoe";
    configurationRevision = inputs.self.rev or inputs.self.dirtyRev or null;
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

  programs.bash.enable = true;
  programs.zsh = {
    enable = true;
    enableAutosuggestions = true;
  };

  fonts.packages = [pkgs.nerd-fonts.jetbrains-mono];

  homebrew = {
    enable = true;
    brews = [
      "mas"
      "sst/tap/opencode"
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
    taps = [
      "sst/tap"
    ];
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

  services = {
    sketchybar = {
      enable = true;
      extraPackages = with pkgs; [
        sbarlua
      ];
    };
    skhd.enable = true;
    yabai.enable = true;
  };

  # $ darwin-rebuild changelog
  system.stateVersion = 6;
}
