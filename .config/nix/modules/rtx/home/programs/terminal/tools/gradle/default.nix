{rtxCerts, ...}: {
  imports = [
    ../../../../../../util/rtx/certs
  ];

  programs.gradle = {
    enable = true;
    settings = {
      "systemProp.http.proxyHost" = "REDACTED";
      "systemProp.http.proxyPort" = "80";
      "systemProp.https.proxyHost" = "REDACTED";
      "systemProp.https.proxyPort" = "80";
      "systemProp.http.nonProxyHosts" = "localhost|*.raytheon.com|*.ray.com|*.rtx.com|*.utc.com|*.adxrt.com|registry.npmjs.org|eks.amazonaws.com";
      "systemProp.https.nonProxyHosts" = "localhost|*.raytheon.com|*.ray.com|*.rtx.com|*.utc.com|*.adxrt.com|registry.npmjs.org|eks.amazonaws.com";
      "systemProp.javax.net.ssl.trustStore" = "${rtxCerts.trustStore}";
      "systemProp.http.connectionTimeout" = "120000";
      "systemProp.http.socketTimeout" = "120000";
      "systemProp.https.connectionTimeout" = "120000";
      "systemProp.https.socketTimeout" = "120000";
    };
  };
}
