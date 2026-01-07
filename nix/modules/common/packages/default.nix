{ pkgs, ... }:
{
  environment = {
    systemPackages = with pkgs; [
      age
      cloudflared
      curl
      pkg-config
      sops
      ssh-to-age
      unzip
      vim
      wget
    ];
  };

  fonts.packages = [ pkgs.nerd-fonts.jetbrains-mono ];
}
