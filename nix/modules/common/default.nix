{ username, ... }:
{
  imports = [
    ./networking
    ./nix
    ./programs
    ./security
  ];

  environment.variables = {
    NIX_DEFAULT_USER = username;
  };
}
