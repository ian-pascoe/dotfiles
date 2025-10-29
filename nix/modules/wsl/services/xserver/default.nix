{
  services.xserver = {
    enable = true;
  };

  environment.extraInit = ''
    export DISPLAY=localhost:0
    export LIBGL_ALWAYS_INDIRECT=true
    export LIBGL_ALWAYS_SOFTWARE=true
  '';
}
