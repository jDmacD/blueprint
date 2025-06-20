{
  config,
  lib,
  pkgs,
  ...
}:
{
  networking.firewall.enable = false;
  networking.firewall.checkReversePath = false;
  networking.firewall.allowedTCPPorts = [
    6443 # k3s: required so that pods can reach the API server (running on port 6443 by default)
    # 2379 # k3s, etcd clients: required if using a "High Availability Embedded etcd" configuration
    # 2380 # k3s, etcd peers: required if using a "High Availability Embedded etcd" configuration
    10250 # metrics port
    4240 # cilium health
    443
    80
  ];
  networking.firewall.allowedUDPPorts = [
    8472 # k3s, flannel: required if using multi-node for inter-node networking
  ];
  # https://search.nixos.org/options?channel=25.05&from=0&size=50&sort=relevance&type=packages&query=services.k3s
  services.k3s = {
    enable = true;
    package = pkgs.k3s_1_33;
    role = "server"; # Or "agent" for worker only nodes
    extraFlags = toString [
      "--disable=traefik"
      "--write-kubeconfig-mode=644"
      "--flannel-backend=none"
      "--disable-network-policy"
      "--disable-kube-proxy"
      "--disable=servicelb"
      "--tls-san ${config.networking.hostName}.lan"
    ];
  };

  environment.systemPackages = with pkgs; [
    kubectl
    k9s
  ];
}
