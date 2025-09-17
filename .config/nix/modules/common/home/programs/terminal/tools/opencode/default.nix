{
  pkgs,
  config,
  dotfiles,
  ...
}: let
  opencode = pkgs.stdenv.mkDerivation rec {
    pname = "opencode";
    version = "0.9.9";

    src = pkgs.fetchzip {
      url = "https://github.com/sst/opencode/releases/download/v${version}/opencode-linux-x64.zip";
      hash = "sha256-jKaC1UGDQb/x08vbfq64gd/607H8b932qvidKHemTc4=";
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
