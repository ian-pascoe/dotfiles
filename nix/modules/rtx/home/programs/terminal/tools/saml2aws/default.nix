{ pkgs, ... }:
let
  playwright_chromium_rev = pkgs.playwright-driver.browsersJSON.chromium.revision;
in
{
  home = {
    packages = with pkgs; [
      playwright-driver.browsers
      saml2aws
    ];

    file.".saml2aws" = {
      source = ./config/saml2aws.ini;
      force = true;
    };

    sessionVariables = with pkgs; {
      PLAYWRIGHT_BROWSERS_PATH = "${playwright-driver.browsers}";
      PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS = 1;
      PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD = 1;
      SAML2AWS_BROWSER_TYPE = "chromium";
      SAML2AWS_BROWSER_EXECUTABLE_PATH = "${playwright-driver.browsers}/chromium-${playwright_chromium_rev}/chrome-linux/chrome";
      SAML2AWS_DISABLE_KEYCHAIN = 1;
    };

    shellAliases = {
      xeta-aws-login = "saml2aws login --verbose --skip-prompt --idp-account=xetagov";
    };
  };
}
