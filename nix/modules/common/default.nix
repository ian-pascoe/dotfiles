{ username, ... }:
{
  time.timeZone = "America/New_York";

  environment.variables = {
    NIX_DEFAULT_USER = username;
  };
}
