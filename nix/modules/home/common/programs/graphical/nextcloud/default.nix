{ pkgs, lib, ... }:
{
  services.nextcloud-client = {
    enable = lib.mkDefault pkgs.stdenv.isLinux; # Mac install handled via homebrew
    startInBackground = lib.mkDefault true;
    package = lib.mkDefault pkgs.stable.nextcloud-client; # TODO: unstable is broken currently
  };
}
