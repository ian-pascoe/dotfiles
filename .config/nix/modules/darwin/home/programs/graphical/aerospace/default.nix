{
  programs.aerospace = {
    enable = true;
    launchd.enable = true;
  };
  xdg.configFile.aerospace = {
    source = ./config;
    recursive = true;
  };
  home.shellAliases = {
    restart-aerospace = ''launchctl kickstart -k gui/"$(id -u)"/org.nix-community.home.aerospace'';
  };
}
