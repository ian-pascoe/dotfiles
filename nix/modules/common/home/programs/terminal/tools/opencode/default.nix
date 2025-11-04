{
  pkgs,
  config,
  dotfiles,
  ...
}:
{
  imports = [
    ../../../../../../util/home/dotfiles
  ];

  programs.opencode = {
    enable = false; # installed via bun
    package = pkgs.nur.repos.falconprogrammer.opencode-sst; # fallback if main is broken
  };

  home.file = {
    ".local/bin/sync-copilot-tokens" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfiles.path}/bin/sync-copilot-tokens";
      force = true;
    };
  };

  xdg.configFile.opencode = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfiles.path}/config/opencode";
    force = true;
  };
}
