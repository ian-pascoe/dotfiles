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
    ];
  };

  fonts.packages = [ pkgs.nerd-fonts.jetbrains-mono ];
}
