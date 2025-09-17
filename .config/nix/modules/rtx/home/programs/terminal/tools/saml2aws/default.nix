{pkgs, ...}: {
  home.packages = with pkgs; [
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
