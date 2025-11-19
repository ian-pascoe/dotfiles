{ rtxCerts, ... }:
{
  programs.gradle.settings = {
    "org.gradle.jvmargs" = "-Djavax.net.ssl.trustStore=${rtxCerts.javaCacerts}";
  };

  home.sessionVariables = {
    GRADLE_OPTS = "-Djavax.net.ssl.trustStore=${rtxCerts.javaCacerts}";
  };
}
