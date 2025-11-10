{
  pkgs,
  config,
  dotfiles,
  ...
}:
let
  zjstatus = pkgs.fetchurl {
    url = "https://github.com/dj95/zjstatus/releases/download/v0.21.1/zjstatus.wasm";
    hash = "sha256-0wpa6hvzizx8zjbz2cja9n4s4yd75vn20q8g5nr9fsr1kff0g9s5";
  };
in
{
  imports = [
    ../../../../../../util/home/dotfiles
  ];

  programs.zellij = {
    enable = true;
  };

  xdg.configFile = {
    "zellij/config.kdl" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfiles.path}/config/zellij/config.kdl";
      force = true;
    };
    "zellij/layouts" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfiles.path}/config/zellij/layouts";
      force = true;
    };
    "zellij/plugins/zjstatus.wasm" = {
      source = zjstatus;
    };
  };
}
