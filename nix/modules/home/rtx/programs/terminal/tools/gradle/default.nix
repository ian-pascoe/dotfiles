{ customLib, ... }:
{
  programs.gradle.settings = {
    "org.gradle.jvmargs" = "-Djavax.net.ssl.trustStore=${customLib.rtx.certs.javaTrustStore}";
  };

  home.sessionVariables = {
    GRADLE_OPTS = "-Djavax.net.ssl.trustStore=${customLib.rtx.certs.javaTrustStore}";
  };
}
