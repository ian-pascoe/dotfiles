{pkgs, ...}: {
  home.packages = with pkgs; [
    xquartz
  ];
  launchd.agents.xquartz = {
    enable = true;
    config = {
      Program = "${pkgs.xquartz}/bin/startx";
      KeepAlive = true;
      RunAtLoad = true;
      StandardOutPath = "/tmp/xquartz.out";
      StandardErrorPath = "/tmp/xquartz.err";
    };
  };
  home.sessionVariables = {
    DISPLAY = ":0";
  };
}
