{ rtxCerts, lib, ... }:
{
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
      "systemProp.http.connectionTimeout" = "300000";
      "systemProp.http.socketTimeout" = "300000";
      "systemProp.https.connectionTimeout" = "300000";
      "systemProp.https.socketTimeout" = "300000";
      "systemProp.org.gradle.internal.http.connectionTimeout" = "300000";
      "systemProp.org.gradle.internal.http.socketTimeout" = "300000";
      "systemProp.org.gradle.internal.https.connectionTimeout" = "300000";
      "systemProp.org.gradle.internal.https.socketTimeout" = "300000";
    };
  };

  home.sessionVariables = {
    GRADLE_OPTS = lib.concatStringsSep " " [
      "-Dhttp.proxyHost=${builtins.getEnv "HTTP_PROXY_HOST"}"
      "-Dhttp.proxyPort=${builtins.getEnv "HTTP_PROXY_PORT"}"
      "-Dhttps.proxyHost=${builtins.getEnv "HTTPS_PROXY_HOST"}"
      "-Dhttps.proxyPort=${builtins.getEnv "HTTPS_PROXY_PORT"}"
      "-Djavax.net.ssl.trustStore=${rtxCerts.trustStore}"
      "-Dhttp.connectionTimeout=300000"
      "-Dhttp.socketTimeout=300000"
      "-Dhttps.connectionTimeout=300000"
      "-Dhttps.socketTimeout=300000"
      "-Dorg.gradle.internal.http.connectionTimeout=300000"
      "-Dorg.gradle.internal.http.socketTimeout=300000"
      "-Dorg.gradle.internal.https.connectionTimeout=300000"
      "-Dorg.gradle.internal.https.socketTimeout=300000"
      "-Dorg.gradle.wrapper.networkTimeout=300000"
    ];
  };
}
