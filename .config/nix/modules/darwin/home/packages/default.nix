{pkgs, ...}: {
  home.packages = with pkgs; [
    mousecape
    nowplaying-cli
  ];
}
