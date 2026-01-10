{ lib, ... }:
{
  programs.rclone = {
    enable = lib.mkDefault true;
  };
}
