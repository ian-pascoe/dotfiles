{
  pkgs,
  config,
  dotfiles,
  ...
}:
{
  imports = [
    ../../../../../../util/home/dotfiles
  ];

  programs.opencode = {
    enable = true;
    # TODO: Switch back to official package when it's fixed.
    package = pkgs.nur.repos.falconprogrammer.opencode-sst;
  };

  xdg.configFile.opencode = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfiles.path}/.config/opencode";
    force = true;
  };
}
