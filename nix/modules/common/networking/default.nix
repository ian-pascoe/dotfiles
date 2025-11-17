{
  pkgs,
  config,
  ...
}:
{
  networking =
    if pkgs.stdenv.isLinux then
      {
        proxy = {
          allProxy = builtins.getEnv "all_proxy";
          httpProxy = builtins.getEnv "http_proxy";
          httpsProxy = builtins.getEnv "https_proxy";
          ftpProxy = builtins.getEnv "ftp_proxy";
          noProxy = builtins.getEnv "no_proxy";
        };
      }
    else
      { };

  # Set upper case versions of the proxy environment variables
  environment.variables =
    if pkgs.stdenv.isLinux then
      {
        ALL_PROXY = config.networking.proxy.allProxy;
        HTTP_PROXY = config.networking.proxy.httpProxy;
        HTTPS_PROXY = config.networking.proxy.httpsProxy;
        FTP_PROXY = config.networking.proxy.ftpProxy;
        NO_PROXY = config.networking.proxy.noProxy;
      }
    else
      {
        all_proxy = builtins.getEnv "all_proxy";
        ALL_PROXY = builtins.getEnv "ALL_PROXY";
        http_proxy = builtins.getEnv "http_proxy";
        HTTP_PROXY = builtins.getEnv "HTTP_PROXY";
        https_proxy = builtins.getEnv "https_proxy";
        HTTPS_PROXY = builtins.getEnv "HTTPS_PROXY";
        ftp_proxy = builtins.getEnv "ftp_proxy";
        FTP_PROXY = builtins.getEnv "FTP_PROXY";
        no_proxy = builtins.getEnv "no_proxy";
        NO_PROXY = builtins.getEnv "NO_PROXY";
      };
}
