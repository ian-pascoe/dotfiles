{pkgs, ...}: {
  home.packages = with pkgs; [
    firefox # Needed for sign-in
    saml2aws
  ];

  xdg.configFile.".saml2aws" = {
    source = ./config/saml2aws.ini;
    force = true;
  };
}
