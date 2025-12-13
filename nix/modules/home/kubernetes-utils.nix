{ pkgs, osConfig, ... }:
{

  home.packages = with pkgs; [
    kubectl
    kustomize
    kubernetes-helm
    kubecm
    k3d
    kubeswitch
    kubernetes-helm
  ];

  programs.k9s = {
    enable = true;
  };

}
