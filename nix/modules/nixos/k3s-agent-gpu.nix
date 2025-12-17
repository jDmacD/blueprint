{
  config,
  lib,
  pkgs,
  inputs,
  perSystem,
  ...
}:
{
  networking.firewall.enable = lib.mkForce false;
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

  hardware.nvidia-container-toolkit.enable = true;

  sops.secrets."k3s/token" = {
    owner = "root";
  };

  services.k3s = {
    enable = true;
    package = perSystem.nixpkgs-25-05.pkgs.k3s_1_31;
    role = "agent";
    tokenFile = "/run/secrets/k3s/token";
    serverAddr = "https://tpi01.lan:6443";
    extraFlags = toString [
      "--node-name ${config.networking.hostName}"
      "--node-taint 'gpu=true:NoSchedule'"
      "--nonroot-devices"
    ];
    containerdConfigTemplate = ''
      {{ template "base" . }}

      [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.nvidia]
        privileged_without_host_devices = false
        runtime_engine = ""
        runtime_root = ""
        runtime_type = "io.containerd.runc.v2"

      [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.nvidia.options]
        BinaryName = "${perSystem.nixpkgs-24-11.pkgs.nvidia-container-toolkit}/bin/nvidia-container-runtime"

    '';
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
    nvidia-container-toolkit
    libnvidia-container
    runc
  ];

  environment.etc."nvidia/nvidia.yaml" = {
    text = ''
      apiVersion: node.k8s.io/v1
      handler: nvidia
      kind: RuntimeClass
      metadata:
        labels:
          app.kubernetes.io/component: gpu-operator
        name: nvidia
    '';
  };
}
