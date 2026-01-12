{ pkgs, ... }:
{
  home = {
    packages = with pkgs; [
      nodejs_24
      prettier
      prettierd
      eslint
      eslint_d
      biome
    ];
    sessionVariables = {
      NODE_USE_ENV_PROXY = "1";
      NODE_USE_SYSTEM_CA = "1";
    };
  };
}
