{
  services.xserver = {
    enable = true;
  };

  environment.variables = {
    DISPLAY = "localhost:0";
    LIBGL_ALWAYS_INDIRECT = 1;
    LIBGL_ALWAYS_SOFTWARE = 1;
  };
}
