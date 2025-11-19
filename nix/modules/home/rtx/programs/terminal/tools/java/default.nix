{ customLib, ... }:
{
  programs.java = {
    enable = true;
  };

  home = {
    sessionVariables = {
      JAVA_TOOL_OPTIONS = "-Djava.net.useSystemProxies=true -Djavax.net.ssl.trustStore=${customLib.rtx.certs.javaTrustStore}";
      _JAVA_OPTIONS = "-Djava.net.useSystemProxies=true -Djavax.net.ssl.trustStore=${customLib.rtx.certs.javaTrustStore}";
    };
  };
}
