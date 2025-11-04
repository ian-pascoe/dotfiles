{ lib, ... }:
{
  programs.java = lib.mkDefault {
    enable = true;
  };

  home.sessionVariables = {
    JAVA_TOOL_OPTIONS = lib.mkDefault "-Djava.net.useSystemProxies=true";
    _JAVA_OPTIONS = lib.mkDefault "-Djava.net.useSystemProxies=true";
  };
}
