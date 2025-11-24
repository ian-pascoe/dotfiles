{ lib, ... }:
let
  httpProxy = builtins.getEnv "HTTP_PROXY";
  hasProxy = httpProxy != "";

  # Parse proxy URL to extract host and port
  # Assumes format like "http://proxy.example.com:8080"
  parseProxy =
    proxy:
    let
      withoutScheme = builtins.replaceStrings [ "http://" "https://" ] [ "" "" ] proxy;
      # Use match instead of split to extract host and port
      matched = builtins.match "([^:]+):([0-9]+)" withoutScheme;
    in
    if matched != null then
      {
        host = builtins.elemAt matched 0;
        port = builtins.elemAt matched 1;
      }
    else
      {
        # Fallback if no port is specified
        host = withoutScheme;
        port = "8080";
      };

  proxyConfig =
    if hasProxy then
      parseProxy httpProxy
    else
      {
        host = "";
        port = "";
      };

  proxySettings = lib.optionalAttrs hasProxy {
    "systemProp.http.proxyHost" = lib.mkDefault proxyConfig.host;
    "systemProp.http.proxyPort" = lib.mkDefault proxyConfig.port;
    "systemProp.https.proxyHost" = lib.mkDefault proxyConfig.host;
    "systemProp.https.proxyPort" = lib.mkDefault proxyConfig.port;
  };
in
{
  programs.gradle = {
    enable = lib.mkDefault true;
    settings = proxySettings;
  };
}
