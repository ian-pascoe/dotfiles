{pkgs, ...}: {
  home.packages = with pkgs; [
    lsof
    nodejs_24
    go
    python3Full
    rustc
    cargo
    lua5_4
    nixd
    alejandra
    gcc
    gnumake
    git-credential-manager
    gnupg
    pass
  ];
}
