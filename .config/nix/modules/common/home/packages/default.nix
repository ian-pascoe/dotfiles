{pkgs, ...}: {
  home.packages = with pkgs; [
    lsof
    nodejs_24
    go
    python313
    rustc
    cargo
    lua5_4
    gcc
    gnumake
    xclip
    kubectl
    kubernetes-helm
  ];
}
