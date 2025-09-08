let
  tomlContent = builtins.readFile ./config/aerospace.toml;
  parsedToml = builtins.fromTOML tomlContent;
in {
  programs.aerospace = {
    enable = true;
    launchd.enable = true;
    userSettings = parsedToml;
  };
  home.shellAliases = {
    restart-aerospace = ''launchctl kickstart -k gui/"$(id -u)"/org.nix-community.home.aerospace'';
  };
}
