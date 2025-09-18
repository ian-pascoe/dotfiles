{
  services.xserver = {
    enable = true;
    desktopManager.gnome.enable = true;
    displayManager.gdm.enable = true;
    windowManager.hypr.enable = true;
  };

  environment.extraInit = ''
    export DISPLAY=localhost:0
    export LIBGL_ALWAYS_INDIRECT=true
    export LIBGL_ALWAYS_SOFTWARE=true
  '';
}
