{ config, ... }:
{
  networking = {
    proxy = {
      allProxy = builtins.getEnv "all_proxy";
      httpProxy = builtins.getEnv "http_proxy";
      httpsProxy = builtins.getEnv "https_proxy";
      ftpProxy = builtins.getEnv "ftp_proxy";
      noProxy = builtins.getEnv "no_proxy";
    };
  };

  # Set upper case versions of the proxy environment variables
  environment.variables = {
    ALL_PROXY = config.networking.proxy.allProxy;
    HTTP_PROXY = config.networking.proxy.httpProxy;
    HTTPS_PROXY = config.networking.proxy.httpsProxy;
    FTP_PROXY = config.networking.proxy.ftpProxy;
    NO_PROXY = config.networking.proxy.noProxy;
  };
}
