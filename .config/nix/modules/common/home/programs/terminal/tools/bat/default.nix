{pkgs, ...}: {
  programs.bat = {
    enable = true;
    extraPackages = with pkgs.bat-extras; [
      batdiff
      batgrep
      batman
      batpipe
      batwatch
      prettybat
    ];
  };
  xdg.configFile.bat = {
    source = ./config;
    force = true;
  };
  home.shellAliases = {
    cat = "bat --style=plain";
  };
}
