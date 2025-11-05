{ pkgs, ... }:
let
  commonSettings = {
    enable = true;
    enableBashCompletion = true;
  };
  # Handle differences in option names between Linux and Darwin
  settings =
    if pkgs.stdenv.isLinux then
      commonSettings
      // {
        autosuggestions.enable = true;
        syntaxHighlighting.enable = true;
      }
    else
      commonSettings
      // {
        enableAutosuggestions = true;
        enableSyntaxHighlighting = true;
      };
in
{
  programs.zsh = settings;
}
