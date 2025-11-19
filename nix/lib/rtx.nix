{
  genCerts =
    { pkgs, ... }:
    let
      certBundle = pkgs.fetchzip {
        url = "https://pki.rtx.com/certificate/RTX_Cert_Bundle-current.zip";
        sha256 = "sha256-q/LYu3oGy1D/r3P2pI7d4IulOfLXV/xt0hFt2mc3i0o=";
      };

      pemFiles = map (f: "${certBundle}/PEM/${f}") (
        builtins.filter (f: builtins.match ".+\\.cer$" f != null) (
          builtins.attrNames (builtins.readDir "${certBundle}/PEM")
        )
      );

      derFiles = map (f: "${certBundle}/DER/${f}") (
        builtins.filter (f: builtins.match ".+\\.cer$" f != null) (
          builtins.attrNames (builtins.readDir "${certBundle}/DER")
        )
      );

      p7bFiles = map (f: "${certBundle}/P7/${f}") (
        builtins.filter (f: builtins.match ".+\\.p7b$" f != null) (
          builtins.attrNames (builtins.readDir "${certBundle}/P7")
        )
      );

      javaCacertsDrv =
        let
          inherit (pkgs) jdk;
          cacertsPath = "${jdk}/lib/openjdk/lib/security/cacerts";
          pemArgs = builtins.concatStringsSep "\n" pemFiles;
        in
        pkgs.runCommand "rtx-cacerts" { } ''
          set -eu

          cp ${cacertsPath} cacerts
          chmod +w cacerts

          for f in ${pemArgs}; do
            alias=$(basename "$f" | sed -e 's/\.[cC][eE][rR]$//' -e 's/[^A-Za-z0-9_.-]/_/g')
            ${jdk}/bin/keytool -importcert -noprompt \
              -keystore cacerts -storepass changeit \
              -file "$f" -alias "$alias" 2>/dev/null
          done

          install -D cacerts "$out/lib/security/cacerts"
        '';
    in
    {
      bundle = certBundle;
      inherit
        pemFiles
        derFiles
        p7bFiles
        javaCacertsDrv
        ;
      javaCacerts = "${javaCacertsDrv}/lib/security/cacerts";
    };
}
