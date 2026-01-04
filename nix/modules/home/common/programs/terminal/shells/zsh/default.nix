{ lib, config, ... }:
{
  programs.zsh = {
    enable = lib.mkDefault true;
    dotDir = "${config.xdg.configHome}/zsh";
    autosuggestion.enable = lib.mkDefault true;
    syntaxHighlighting.enable = lib.mkDefault true;
  };
}
