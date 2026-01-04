{
  config,
  lib,
  dotfiles,
  ...
}:
{
  programs.opencode = {
    enable = lib.mkDefault true;
  };

  home.file = {
    ".local/bin/sync-copilot-tokens" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfiles.path}/bin/sync-copilot-tokens";
      force = true;
    };
  };

  xdg.configFile = {
    opencode = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfiles.path}/config/opencode";
      force = true;
    };
  };
}
