{
  pkgs,
  config,
  lib,
  dotfiles,
  ...
}:
let
  vimZellijNavigatorVersion = "0.3.0";
  vimZellijNavigator = pkgs.fetchurl {
    url = "https://github.com/hiasr/vim-zellij-navigator/releases/download/${vimZellijNavigatorVersion}/vim-zellij-navigator.wasm";
    hash = "sha256-d+Wi9i98GmmMryV0ST1ddVh+D9h3z7o0xIyvcxwkxY0=";
  };

  zjstatusVersion = "0.21.1";
  zjstatus = pkgs.fetchurl {
    url = "https://github.com/dj95/zjstatus/releases/download/v${zjstatusVersion}/zjstatus.wasm";
    hash = "sha256-3BmCogjCf2aHHmmBFFj7savbFeKGYv3bE2tXXWVkrho=";
  };
in
{
  programs.zellij = {
    enable = lib.mkDefault true;
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
    "zellij/plugins/vim-zellij-navigator.wasm" = {
      source = vimZellijNavigator;
      force = true;
    };
    "zellij/plugins/zjstatus.wasm" = {
      source = zjstatus;
      force = true;
    };
  };
}
