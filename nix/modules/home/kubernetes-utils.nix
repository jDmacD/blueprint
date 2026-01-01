{ pkgs, osConfig, ... }:
{

  home.packages = with pkgs; [
    kubectl
    kustomize
    kubernetes-helm
    kubecm
    k3d
    kubeswitch
    kubectl-cnpg
    cilium-cli
    hubble
  ];

  programs.k9s = {
    enable = true;
  };

}
