{
  imports = [
    ./packages
    ./programs
    ../../util/home/dotfiles
  ];
  xdg.enable = true;
  systemd.user.startServices = "sd-switch";
  home.stateVersion = "25.05";
}
