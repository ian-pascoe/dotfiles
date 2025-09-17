{
  services.xserver = {
    enable = true;
    desktopManager.xfce.enable = true;
    displayManager.gdm.enable = true;
    windowManager.hypr.enable = true;
  };

  environment.extraInit = ''
    export DISPLAY=localhost:0.0
    export LIBGL_ALWAYS_INDIRECT=1
  '';
}
