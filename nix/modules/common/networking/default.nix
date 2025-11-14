{
  networking = {
    proxy = {
      default = builtins.getEnv "all_proxy";
      noProxy = builtins.getEnv "no_proxy";
    };
  };
}
