{pkgs, ...}: {
  home.packages = with pkgs; [
    ant
    maven
    kubectl
    kubernetes-helm
  ];
}
