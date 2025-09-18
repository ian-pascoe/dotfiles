{pkgs, ...}: {
  home.packages = with pkgs; [
    powershell
  ];
}
