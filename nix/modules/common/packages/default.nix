{ pkgs, ... }:
{
  environment = {
    systemPackages = with pkgs; [
      curl
      wget
      unzip
      vim
      pkg-config
      age
      cloudflared
    ];
  };

  fonts.packages = [ pkgs.nerd-fonts.jetbrains-mono ];
}
