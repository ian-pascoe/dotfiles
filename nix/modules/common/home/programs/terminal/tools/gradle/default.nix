{ lib, ... }:
{
  programs.gradle = lib.mkDefault {
    enable = true;
    settings = {
      "org.gradle.jvmargs" = "-Djava.net.useSystemProxies=true";
    };
  };
}
