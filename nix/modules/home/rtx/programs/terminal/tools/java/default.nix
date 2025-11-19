{ rtxCerts, ... }:
{
  programs.java = {
    enable = true;
  };

  home = {
    sessionVariables = {
      JAVA_TOOL_OPTIONS = "-Djava.net.useSystemProxies=true -Djavax.net.ssl.trustStore=${rtxCerts.javaCacerts}";
      _JAVA_OPTIONS = "-Djava.net.useSystemProxies=true -Djavax.net.ssl.trustStore=${rtxCerts.javaCacerts}";
    };
  };
}
