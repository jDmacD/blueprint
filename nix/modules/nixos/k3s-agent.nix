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

  services.k3s = {
    enable = true;
    package = pkgs.unstable.k3s_1_30;
    role = "agent"; # Or "agent" for worker only nodes
    # sudo cat /var/lib/rancher/k3s/server/agent-token
    token = "K10d3eae50e388e04587ce0188128e9b04b4b92a2f6aa0e14981483dc6e1e5fbe26::server:b1dbb3ed45a79cbb4f0c20c87c01b8b5";
    serverAddr = "https://tpi01.lan:6443";
    extraFlags = toString [
      # otherwise the node will pull the nixos-rpi hostname of the bootstapper
      "--node-name ${config.networking.hostName}"
    ];
  };

  # needed for ceph
  fileSystems."/lib/modules" = {
    device = "/run/booted-system/kernel-modules/lib/modules";
    fsType = "none";
    options = [ "bind" ];
    depends = [ "/run/booted-system/kernel-modules/lib/modules" ];
  };

  programs.nbd.enable = true; # required for ceph

  environment.systemPackages = with pkgs; [
    lvm2
  ];
}
