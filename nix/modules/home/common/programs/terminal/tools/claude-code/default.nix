{
  pkgs,
  config,
  lib,
  dotfiles,
  ...
}:
{
  programs.claude-code = {
    enable = lib.mkDefault pkgs.stdenv.isLinux; # handled via homebrew on mac
  };

  home.file = {
    ".claude/settings.json" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfiles.path}/config/claude-code/settings.json";
      force = true;
    };
    ".claude/agents" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfiles.path}/config/claude-code/agents";
      force = true;
    };
    ".claude/commands" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfiles.path}/config/claude-code/commands";
      force = true;
    };
    ".claude/skills" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfiles.path}/config/claude-code/skills";
      force = true;
    };
  };
}
