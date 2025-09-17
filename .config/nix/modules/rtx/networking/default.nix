{
  networking = {
    hostName = "EC1414438";
    proxy.default = "http://proxygov.ray.com:80/";
    proxy.noProxy = "localhost,127.0.0.1,.raytheon.com,.ray.com,.rtx.com,.utc.com,.adxrt.com,.registry.npmjs.org,.eks.amazonaws.com";
  };

  environment = {
    sessionVariables = {
      http_proxy = "http://proxygov.ray.com:80/";
      https_proxy = "http://proxygov.ray.com:80/";
      HTTP_PROXY = "http://proxygov.ray.com:80/";
      HTTPS_PROXY = "http://proxygov.ray.com:80/";
      all_proxy = "http://proxygov.ray.com:80/";
      ALL_PROXY = "http://proxygov.ray.com:80/";
      no_proxy = "localhost,127.0.0.1,.raytheon.com,.ray.com,.rtx.com,.utc.com,.adxrt.com,.registry.npmjs.org,.eks.amazonaws.com";
      NO_PROXY = "localhost,127.0.0.1,.raytheon.com,.ray.com,.rtx.com,.utc.com,.adxrt.com,.registry.npmjs.org,.eks.amazonaws.com";

      # Used by lemminx
      HTTP_PROXY_HOST = "proxygov.ray.com";
      HTTP_PROXY_PORT = "80";
    };
  };
}
