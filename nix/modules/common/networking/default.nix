{
  networking = {
    proxy.default = builtins.getEnv "ALL_PROXY";
  };

  environment.variables = {
    ALL_PROXY = builtins.getEnv "ALL_PROXY";
    all_proxy = builtins.getEnv "all_proxy";

    HTTP_PROXY = builtins.getEnv "HTTP_PROXY";
    http_proxy = builtins.getEnv "http_proxy";

    HTTPS_PROXY = builtins.getEnv "HTTPS_PROXY";
    https_proxy = builtins.getEnv "https_proxy";

    NO_PROXY = builtins.getEnv "NO_PROXY";
    no_proxy = builtins.getEnv "no_proxy";
  };
}
