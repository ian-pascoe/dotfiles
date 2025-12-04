{ pkgs, ... }:
{
  _module.args = {
    buildCustomPythonPackages =
      pythonPackages:
      pythonPackages.overrideScope (
        pyFinal: pyPrev: {
          # TODO: Remove this once newer package is available
          gehomesdk = pyPrev.buildPythonPackage rec {
            pname = "gehomesdk";
            version = "2025.11.5";
            pyproject = true;

            disabled = pyPrev.pythonOlder "3.9";

            src = pyPrev.fetchPypi {
              inherit pname version;
              hash = "sha256-HS33yTE+3n0DKRD4+cr8zAE+xcW1ca7q8inQ7qwKJMA=";
            };

            build-system = with pyPrev; [ setuptools ];

            dependencies = with pyPrev; [
              aiohttp
              beautifulsoup4
              bidict
              humanize
              lxml
              requests
              slixmpp
              websockets
            ];

            # Tests are not shipped and source is not tagged
            # https://github.com/simbaja/gehome/issues/32
            doCheck = false;

            pythonImportsCheck = [ "gehomesdk" ];
          };
          magicattr = pyPrev.buildPythonPackage rec {
            pname = "magicattr";
            version = "0.1.6";
            pyproject = true;

            disabled = pyPrev.pythonOlder "3.9";

            src = pkgs.fetchFromGitHub {
              owner = "frmdstryr";
              repo = "magicattr";
              rev = "v${version}";
              hash = "sha256-hV425AnXoYL3oSYMhbXaF8VRe/B1s5f5noAZYz4MMwc=";
            };

            build-system = with pyPrev; [ setuptools ];

            pythonImportsCheck = [ "magicattr" ];
          };
          hatch-rest-api = pyPrev.buildPythonPackage rec {
            pname = "hatch-rest-api";
            version = "1.30.0";
            pyproject = true;

            disabled = pyPrev.pythonOlder "3.9";

            src = pkgs.fetchFromGitHub {
              owner = "dahlb";
              repo = "hatch_rest_api";
              rev = "v${version}";
              hash = "sha256-9FJSlFpsfNbFJ5b/IPBAt6rBAAhtuXYrTw0qrPMiOf4=";
            };

            build-system = with pyPrev; [ setuptools ];

            dependencies = with pyPrev; [
              wheel
              ruff
              aiohttp
              awsiotsdk
            ];

            pythonImportsCheck = [ "hatch_rest_api" ];
          };
          # TODO: Remove this once newer package is available
          sharkiq = pyPrev.buildPythonPackage rec {
            pname = "sharkiq";
            version = "1.4.3";
            pyproject = true;

            disabled = pyPrev.pythonOlder "3.9";

            src = pkgs.fetchFromGitHub {
              owner = "sharkiqlibs";
              repo = "sharkiq";
              tag = "v${version}";
              hash = "sha256-SZAOV9a3hy3RDIQVA0pzquNS1OxzAsTd1veo2fqjaNU=";
            };

            postPatch = ''
              substituteInPlace pyproject.toml \
                --replace-fail "setuptools-scm>=9.2.0" "setuptools-scm"
            '';

            build-system = with pyPrev; [
              setuptools
              setuptools-scm
            ];

            dependencies = with pyPrev; [
              aiohttp
              auth0-python
              requests
            ];

            # Module has no tests
            doCheck = false;

            pythonImportsCheck = [ "sharkiq" ];
          };
        }
      );
  };
}
