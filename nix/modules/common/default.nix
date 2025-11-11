{ username, ... }:
{
  imports = [
    ./nix
    ./programs
  ];

  environment.variables = {
    NIX_DEFAULT_USER = username;
  };
}
