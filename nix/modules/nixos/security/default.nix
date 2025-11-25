{ lib, ... }:
{
  security.rtkit = {
    enable = lib.mkDefault true;
  };
}
