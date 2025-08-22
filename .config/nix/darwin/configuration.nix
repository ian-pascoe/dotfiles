{
  inputs,
  lib,
  config,
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
      allowBroken = true;
    };
  };

  nix.settings.experimental-features = "nix-command flakes";

  system.primaryUser = "ianpascoe";
  system.configurationRevision = inputs.self.rev or inputs.self.dirtyRev or null;

  environment = {
    systemPackages = [ pkgs.nushell ];
    shells = [ pkgs.nushell ];
  };

  programs.bash.enable = true;
  programs.zsh = {
    enable = true;
    enableAutosuggestions = true;
  };

  homebrew = {
    enable = true;
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
