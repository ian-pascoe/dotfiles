{
  pkgs,
  config,
  dotfiles,
  ...
}: let
  opencode = pkgs.stdenv.mkDerivation rec {
    pname = "opencode";
    version = "0.9.5";

    src = pkgs.fetchzip {
      url = "https://github.com/sst/opencode/releases/download/v${version}/opencode-linux-x64.zip";
      hash = "sha256-NkLzGgr9kZKUTzW01VBHHIuz04T3wqlBzn0N1QlmDC4=";
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
