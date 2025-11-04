{ lib, ... }:
{
  programs.java = lib.mkDefault {
    enable = true;
  };

  home.sessionVariables = lib.mkDefault {
    JAVA_TOOL_OPTIONS = "-Djava.net.useSystemProxies=true";
    _JAVA_OPTIONS = "-Djava.net.useSystemProxies=true";
  };
}
