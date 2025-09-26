{pkgs, ...}: {
  home.packages = with pkgs; [
    blueutil
    coreutils
  ];
}
