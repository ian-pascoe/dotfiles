{
  services.syncthing = {
    enable = true;
  };

  home.shellAliases = {
    restart-syncthing = ''launchctl kickstart -k gui/"$(id -u)"/org.nix-community.home.syncthing'';
  };
}
