{pkgs, ...}: {
  programs.git = {
    enable = true;
    lfs.enable = true;
  };

  # Set up credentials caching via GPG and pass
  programs.gpg = {
    enable = true;
    settings = {
      trust-model = "tofu+pgp";
    };
  };

  services.gpg-agent = {
    enable = true;
    defaultCacheTtl = 1800;
    enableSshSupport = true;
    pinentry.package = pkgs.pinentry-curses;
  };

  programs.password-store = {
    enable = true;
    settings = {
      PASSWORD_STORE_DIR = "$HOME/.password-store";
    };
  };

  # Auto-setup script for GPG and pass
  home.activation.setupGitCredentials = ''
    if [ ! -f "$HOME/.gpg-key-generated" ]; then
      $DRY_RUN_CMD ${pkgs.gnupg}/bin/gpg --batch --generate-key <<EOF
    %no-protection
    Key-Type: RSA
    Key-Length: 2048
    Subkey-Type: RSA
    Subkey-Length: 2048
    Name-Real: Ian Pascoe (Git Credentials)
    Name-Email: ian.g.pascoe@gmail.com
    Expire-Date: 0
    %commit
    EOF
      touch "$HOME/.gpg-key-generated"

      # Initialize password store with the generated key
      KEY_ID=$(${pkgs.gnupg}/bin/gpg --list-secret-keys --keyid-format LONG | grep sec | head -n1 | sed 's/.*\/\([^ ]*\) .*/\1/')
      $DRY_RUN_CMD ${pkgs.pass}/bin/pass init "$KEY_ID"
    fi
  '';

  home.sessionVariables = {
    GCM_CREDENTIAL_STORE="gpg";
    GPG_TTY="$(tty)";
  };
}
