{
  config,
  pkgs,
  inputs,
  perSystem,
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

  sops.secrets."k3s/token" = {
    owner = "root";
  };

  services.k3s = {
    enable = true;
    package = inputs.self.lib.k3s { inherit pkgs; };
    role = "agent"; # Or "agent" for worker only nodes
    # sudo cat /var/lib/rancher/k3s/server/agent-token
    # use sops to write out the token file
    tokenFile = "/run/secrets/k3s/token";
    serverAddr = "https://tpi01.lan:6443";
    extraFlags = toString [
      # Otherwise the node will pull the nixos-rpi hostname of the bootstapper
      "--node-name ${config.networking.hostName}"
      # This is for later versions of k3s, maybe.
      # I can't rember why I set it
      # "--nonroot-devices"
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
