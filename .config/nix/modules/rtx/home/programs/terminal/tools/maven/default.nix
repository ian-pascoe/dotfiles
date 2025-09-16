{pkgs, ...}: {
  home.packages = with pkgs; [
    maven
  ];
  home.file.".m2/settings.xml".source = ./config/settings.xml;
}
