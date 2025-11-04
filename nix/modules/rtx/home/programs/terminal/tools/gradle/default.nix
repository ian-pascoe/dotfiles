{ rtxCerts, ... }:
{
  imports = [
    ../../../../../../util/rtx/certs
  ];

  programs.gradle = {
    enable = true;
    settings = {
      "org.gradle.jvmargs" =
        "-Djava.net.useSystemProxies=true -Djavax.net.ssl.trustStore=${rtxCerts.trustStore}";
    };
  };

  home.sessionVariables = {
    GRADLE_OPTS = "-Djava.net.useSystemProxies=true -Djavax.net.ssl.trustStore=${rtxCerts.trustStore}";
  };
}
