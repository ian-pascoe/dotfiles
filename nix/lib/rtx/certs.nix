{ pkgs, ... }:
let
  certBundle = pkgs.fetchzip {
    url = "https://pki.rtx.com/certificate/RTX_Cert_Bundle-current.zip";
    sha256 = "sha256-q/LYu3oGy1D/r3P2pI7d4IulOfLXV/xt0hFt2mc3i0o=";
  };

  pemFiles = map (f: "${certBundle}/PEM/${f}") (
    builtins.filter (
      f: f != "." && f != ".." && f != "README.txt" && builtins.match ".+\\.cer$" f != null
    ) (builtins.attrNames (builtins.readDir "${certBundle}/PEM"))
  );

  javaCacerts =
    pkgs.runCommand "rtx-cacerts"
      {
        buildInputs = [ pkgs.jdk ];
      }
      ''
        set -eu
        mkdir work
        cp ${pkgs.jdk}/lib/openjdk/lib/security/cacerts work/orig
        cp work/orig cacerts
        chmod +w cacerts
        for f in ${builtins.concatStringsSep " " pemFiles}; do
          alias=$(basename "$f" | sed -e 's/\.[cC][eE][rR]$//' -e 's/[^A-Za-z0-9_.-]/_/g')
          ${pkgs.jdk}/bin/keytool -importcert -noprompt \
            -keystore cacerts -storepass changeit \
            -file "$f" -alias "$alias" 2>/dev/null
        done
        mkdir -p $out/lib/openjdk/lib/security
        cp cacerts $out/lib/openjdk/lib/security/cacerts
      '';
in
{
  certs = {
    bundle = certBundle;
    inherit pemFiles;
    javaTrustStore = "${javaCacerts}/lib/openjdk/lib/security/cacerts";
  };
}
