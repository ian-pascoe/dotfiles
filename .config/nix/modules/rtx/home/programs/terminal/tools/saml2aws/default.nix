{pkgs, ...}: {
  home.packages = with pkgs; [
    playwright
    playwright-driver
    playwright-driver.browsers
    saml2aws
  ];

  home.file.".saml2aws" = {
    source = ./config/saml2aws.ini;
    force = true;
  };

  home.sessionVariables = {
    PLAYWRIGHT_BROWSERS_PATH = "${pkgs.playwright-driver.browsers}";
    PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS = "true";
  };
}
