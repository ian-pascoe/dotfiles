{
  imports = [
    ./packages
    ./programs
    ../../util/home/dotfiles
  ];
  home.shell = {
    enableShellIntegration = true;
  };
  xdg.enable = true;
  systemd.user.startServices = "sd-switch";
  home.stateVersion = "25.05";
}
