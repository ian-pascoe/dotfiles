{ inputs, username, ... }:
{
  time.timeZone = "America/New_York";

  environment.variables = {
    NIX_DEFAULT_USER = username;
  };

  system = {
    configurationRevision = inputs.self.rev or inputs.self.dirtyRev or null;
  };
}
