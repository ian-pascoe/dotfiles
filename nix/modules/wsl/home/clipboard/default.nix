{ config, dotfiles, ... }:
{
  imports = [
    ../../../util/home/dotfiles
  ];

  home.file = {
    ".local/bin/wl-copy" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfiles.path}/bin/wl-copy";
      force = true;
    };
    ".local/bin/wl-paste" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfiles.path}/bin/wl-paste";
      force = true;
    };
  };
}
