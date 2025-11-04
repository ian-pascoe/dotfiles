{
  networking = {
    proxy = {
      default = builtins.getEnv "HTTP_PROXY";
    };
  };
  environment.variables = {
    http_proxy = builtins.getEnv "HTTP_PROXY";

    HTTPS_PROXY = builtins.getEnv "HTTP_PROXY";
    https_proxy = builtins.getEnv "HTTP_PROXY";

    ALL_PROXY = builtins.getEnv "HTTP_PROXY";
    all_proxy = builtins.getEnv "HTTP_PROXY";
  };
}
