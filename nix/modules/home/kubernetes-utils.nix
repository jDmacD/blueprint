{ pkgs, osConfig, ... }:
{

  home.packages = [
    pkgs.kubectl
    pkgs.kustomize
    pkgs.kubernetes-helm
    pkgs.kubecm
    pkgs.k3d
  ];
  programs.k9s = {
    enable = true;
  };

}