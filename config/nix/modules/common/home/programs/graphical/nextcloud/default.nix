{ pkgs, ... }:
{
  services.nextcloud-client = {
    enable = pkgs.stdenv.isLinux; # Mac install handled via homebrew
    startInBackground = true;
    package = pkgs.stable.nextcloud-client; # TODO: unstable is broken currently
  };
}
