{
  networking = {
    hostName = "EC1414438";
    proxy.default = builtins.getEnv "HTTP_PROXY";
    proxy.noProxy = builtins.getEnv "NO_PROXY";
  };

  environment = {
    sessionVariables = {
      http_proxy = builtins.getEnv "HTTP_PROXY";
      https_proxy = builtins.getEnv "HTTP_PROXY";

      HTTP_PROXY = builtins.getEnv "HTTP_PROXY";
      HTTPS_PROXY = builtins.getEnv "HTTP_PROXY";

      all_proxy = builtins.getEnv "ALL_PROXY";
      ALL_PROXY = builtins.getEnv "ALL_PROXY";

      no_proxy = builtins.getEnv "NO_PROXY";
      NO_PROXY = builtins.getEnv "NO_PROXY";

      HTTP_PROXY_HOST = builtins.getEnv "HTTP_PROXY_HOST";
      HTTP_PROXY_PORT = builtins.getEnv "HTTP_PROXY_PORT";
      HTTP_NON_PROXY_HOSTS = builtins.getEnv "HTTP_NON_PROXY_HOSTS";

      HTTPS_PROXY_HOST = builtins.getEnv "HTTPS_PROXY_HOST";
      HTTPS_PROXY_PORT = builtins.getEnv "HTTPS_PROXY_PORT";
      HTTPS_NON_PROXY_HOSTS = builtins.getEnv "HTTPS_NON_PROXY_HOSTS";

      NODE_USE_ENV_PROXY = "1";
    };
  };
}
