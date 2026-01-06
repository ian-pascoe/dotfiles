{ lib, ... }:
{
  programs.claude-code = {
    enable = lib.mkDefault true;
  };
}
