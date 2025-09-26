{rtxCerts, ...}: {
  imports = [
    ../../../../../../util/rtx/certs
  ];

  programs.gradle = {
    enable = true;
    settings = {
      "systemProp.http.proxyHost" = builtins.getEnv "HTTP_PROXY_HOST";
      "systemProp.http.proxyPort" = builtins.getEnv "HTTP_PROXY_PORT";
      "systemProp.https.proxyHost" = builtins.getEnv "HTTPS_PROXY_HOST";
      "systemProp.https.proxyPort" = builtins.getEnv "HTTPS_PROXY_PORT";
      "systemProp.http.nonProxyHosts" = builtins.getEnv "HTTP_NON_PROXY_HOSTS";
      "systemProp.https.nonProxyHosts" = builtins.getEnv "HTTPS_NON_PROXY_HOSTS";
      "systemProp.javax.net.ssl.trustStore" = "${rtxCerts.trustStore}";
      "systemProp.http.connectionTimeout" = "120000";
      "systemProp.http.socketTimeout" = "120000";
      "systemProp.https.connectionTimeout" = "120000";
      "systemProp.https.socketTimeout" = "120000";
    };
  };
}
