{
  config,
  dotfiles,
  ...
}:
{
  imports = [
    ../../../../../util/home/dotfiles
  ];

  programs.aerospace = {
    enable = true;
    launchd.enable = true;
  };

  # Disable built-in defaults
  home.file = {
    ".config/aerospace/aerospace.toml" = {
      enable = false;
    };
  };
  xdg.configFile.aerospace = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfiles.path}/.config/aerospace";
    force = true;
  };

  home.shellAliases = {
    restart-aerospace = ''launchctl kickstart -k gui/"$(id -u)"/org.nix-community.home.aerospace'';
  };
}
