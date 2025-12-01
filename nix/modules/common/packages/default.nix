{ pkgs, ... }:
{
  environment = {
    systemPackages = with pkgs; [
      pkg-config
      curl
      wget
      unzip
      vim
      age
      ssh-to-age
      sops
      cloudflared
    ];
  };

  fonts.packages = [ pkgs.nerd-fonts.jetbrains-mono ];
}
