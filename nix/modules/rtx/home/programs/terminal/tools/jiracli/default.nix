{ pkgs, ... }:
{
  home.packages = with pkgs; [
    jira-cli-go
  ];

  home.sessionVariables = {
    JIRA_AUTH_TYPE = "bearer";
    JIRA_API_TOKEN = builtins.getEnv "JIRA_API_TOKEN";
  };
}
