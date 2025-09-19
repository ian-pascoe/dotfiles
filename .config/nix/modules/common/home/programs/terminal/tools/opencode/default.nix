{
  pkgs,
  config,
  dotfiles,
  ...
}: let
  opencode = pkgs.stdenv.mkDerivation rec {
    pname = "opencode";
    version = "0.10.1";

    src = pkgs.fetchzip {
      url = "https://github.com/sst/opencode/releases/download/v${version}/opencode-linux-x64.zip";
      hash = "sha256-lCBsdKG347f0Ci3KtkAYal58wgo6XaR2+GztapsIHoQ=";
    };

    phases = ["installPhase" "patchPhase"];
    installPhase = ''
      mkdir -p $out/bin
      cp $src/opencode $out/bin/opencode
      chmod +x $out/bin/opencode
    '';
  };
in {
  imports = [
    ../../../../../../util/home/dotfiles
  ];
  programs.opencode = {
    enable = true;
    package = opencode;
  };
  xdg.configFile.opencode = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfiles.path}/.config/opencode";
    force = true;
  };
}
