{ rtxCerts, ... }:
{
  imports = [
    ../../../../../../util/rtx/certs
  ];

  programs.gradle.settings = {
    "org.gradle.jvmargs" = "-Djavax.net.ssl.trustStore=${rtxCerts.trustStore}";
  };

  home.sessionVariables = {
    GRADLE_OPTS = "-Djavax.net.ssl.trustStore=${rtxCerts.trustStore}";
  };
}
