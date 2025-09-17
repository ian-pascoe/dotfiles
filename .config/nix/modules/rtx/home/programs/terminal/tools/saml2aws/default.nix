{pkgs, ...}: {
  home.packages = with pkgs; [
    playwright-driver
    playwright.browsers
    saml2aws
  ];

  home.file.".saml2aws" = {
    source = ./config/saml2aws.ini;
    force = true;
  };
}
