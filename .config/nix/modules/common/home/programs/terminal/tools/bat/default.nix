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
    recursive = true;
  };
  home.shellAliases = {
    cat = "bat --paging=never";
  };
}
