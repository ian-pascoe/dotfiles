{ pkgs, lib, ... }:
{
  _module.args = {
    hacs = pkgs.buildHomeAssistantComponent rec {
      owner = "hacs";
      domain = "hacs";
      version = "2.0.5";

      src = pkgs.fetchzip {
        url = "https://github.com/hacs/integration/releases/download/${version}/hacs.zip";
        hash = "sha256-iMomioxH7Iydy+bzJDbZxt6BX31UkCvqhXrxYFQV8Gw=";
        stripRoot = false;
      };

      dependencies = with pkgs.python3Packages; [
        aiogithubapi
      ];

      meta = rec {
        description = "Home Assistant Community Store";
        homepage = "https://github.com/hacs/integration";
        changelog = "${homepage}/releases/tag/${version}";
        license = lib.licenses.unlicense;
      };
    };
  };
}
