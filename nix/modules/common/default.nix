{ inputs, ... }:
{
  time.timeZone = "America/New_York";

  system = {
    configurationRevision = inputs.self.rev or inputs.self.dirtyRev or null;
  };
}
