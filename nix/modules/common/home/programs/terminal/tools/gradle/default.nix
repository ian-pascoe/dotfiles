{ lib, ... }:
{
  programs.gradle = lib.mkDefault {
    enable = true;
  };
}
