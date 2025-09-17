{pkgs, ...}: let
  saml2aws-rtx = pkgs.stdenv.mkDerivation {
    pname = "saml2aws-rtx";
    version = "1.0.0";

    src = pkgs.fetchurl {
      url = "https://confluence.utc.com/download/attachments/198517569/saml2aws-rtx-linux-amd64.zip?version=1&modificationDate=1712081812048&api=v2&download=true";
      sha256 = "0000000000000000000000000000000000000000000000000000000000000000";
    };

    nativeBuildInputs = with pkgs; [unzip];

    unpackPhase = ''
      unzip $src
    '';

    installPhase = ''
      mkdir -p $out/bin $out/share/saml2aws-rtx
      cp saml2aws-rtx $out/bin/saml2aws-rtx
      chmod +x $out/bin/saml2aws-rtx
    '';

    meta = with pkgs.lib; {
      description = "RTX-provided saml2aws utility for AWS authentication";
      platforms = platforms.linux;
    };
  };
in {
  home.packages = [
    pkgs.firefox # Needed for sign-in
    saml2aws-rtx
  ];

  xdg.configFile."saml2aws-rtx" = {
    source = ./config;
    force = true;
  };
}
