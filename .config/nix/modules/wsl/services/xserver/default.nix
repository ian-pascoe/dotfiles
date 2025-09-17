{
  services.xserver = {
    enable = true;
    displayManager.lightdm.enable = true;
    desktopManager.xfce.enable = true;
  };

  environment.extraInit = ''
    export DISPLAY=$(cat /etc/resolv.conf | grep nameserver | awk '{print $2}'):0
  '';
}
