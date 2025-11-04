{ pkgs, ... }:
{
  home = {
    packages = with pkgs; [
      nodejs_24
    ];
    sessionVariables = {
      NODE_USE_ENV_PROXY = "1";
      NODE_USE_SYSTEM_CA = "1";
    };
  };
}
