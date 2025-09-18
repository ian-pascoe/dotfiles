{pkgs, ...}: let
  playwright_chromium_rev = pkgs.playwright.browsersJSON.chromium.revision;
in {
  home.packages = with pkgs; [
    playwright.browsers
    saml2aws
  ];

  home.file.".saml2aws" = {
    source = ./config/saml2aws.ini;
    force = true;
  };

  home.sessionVariables = with pkgs; {
    PLAYWRIGHT_BROWSERS_PATH = "${playwright.browsers}";
    PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS = "true";
    PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD = "true";
    SAML2AWS_BROWSER_EXECUTABLE_PATH = "${playwright.browsers}/chromium-${playwright_chromium_rev}/chrome-linux/chrome";
    SAML2AWS_DISABLE_KEYCHAIN = "true";
  };
}
