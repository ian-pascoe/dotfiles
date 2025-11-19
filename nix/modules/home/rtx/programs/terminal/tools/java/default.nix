{ rtxCerts, ... }:
{
  programs.java = {
    enable = true;
  };

  home = {
    sessionVariables = {
      JAVA_TOOL_OPTIONS = "-Djava.net.useSystemProxies=true -Djavax.net.ssl.trustStore=${rtxCerts.trustStore}";
      _JAVA_OPTIONS = "-Djava.net.useSystemProxies=true -Djavax.net.ssl.trustStore=${rtxCerts.trustStore}";
    };
  };
}
