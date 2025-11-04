{ lib, ... }:
{
  programs.gradle = lib.mkDefault {
    enable = true;
    settings = {
      "org.gradle.jvmargs" = "-Djava.net.useSystemProxies=true";
    };
  };

  home.sessionVariables = {
    GRADLE_OPTS = lib.mkDefault "-Djava.net.useSystemProxies=true";
  };
}
