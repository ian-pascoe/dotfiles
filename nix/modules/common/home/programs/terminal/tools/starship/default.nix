{
  lib,
  config,
  dotfiles,
  ...
}:
{
  imports = [
    ../../../../../../util/home/dotfiles
  ];

  programs.starship = {
    enable = true;
  };

  home.activation = {
    setupStarship = lib.hm.dag.entryAfter [ "programs.starship.enable" ] ''
      if [ ! -f "${config.xdg.configHome}/starship.toml" ]; then
        ln -snf "${dotfiles.path}/config/starship.toml" "${config.xdg.configHome}/starship.toml"
      else
        echo "Starship config file already exists, skipping symlink."
      fi
    '';
  };
}
