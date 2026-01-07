{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    beads
    xclip
  ];
}
