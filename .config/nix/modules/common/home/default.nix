{
  imports = [
    ./packages
    ./programs
  ];
  xdg.enable = true;
  systemd.user.startServices = "sd-switch";
  home.stateVersion = "25.05";
}
