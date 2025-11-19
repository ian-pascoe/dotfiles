{ username, ... }:
{
  environment.variables = {
    NIX_DEFAULT_USER = username;
  };
}
