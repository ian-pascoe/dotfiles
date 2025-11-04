{
  networking = {
    proxy = {
      default = builtins.getEnv "HTTP_PROXY";
    };
  };
  environment.variables = {
    HTTPS_PROXY = builtins.getEnv "HTTP_PROXY";
    ALL_PROXY = builtins.getEnv "HTTP_PROXY";
  };
}
