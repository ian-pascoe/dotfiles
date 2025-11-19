{ lib, ... }:
{
  programs.java = {
    enable = lib.mkDefault true;
  };

  home.sessionVariables = {
    JAVA_TOOL_OPTIONS = lib.mkDefault "-Djava.net.useSystemProxies=true";
    _JAVA_OPTIONS = lib.mkDefault "-Djava.net.useSystemProxies=true";
  };
}
