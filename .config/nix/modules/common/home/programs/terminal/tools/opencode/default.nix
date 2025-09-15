{
  pkgs,
  config,
  dotfiles,
  ...
}: let
  opencode = pkgs.stdenv.mkDerivation rec {
    pname = "opencode";
    version = "0.9.0";

    src = pkgs.fetchzip {
      url = "https://github.com/sst/opencode/releases/download/v${version}/opencode-linux-x64.zip";
      hash = "sha256-y2Z7XTZrEehG98RT3Mi8BCkDW6drLTtUXzxv6zk7BC0=";
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
