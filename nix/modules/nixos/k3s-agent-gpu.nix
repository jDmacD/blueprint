{
  config,
  lib,
  pkgs,
  inputs,
  perSystem,
  ...
}:
let
  nvidia-container-toolkit = perSystem.nixpkgs-stable.nvidia-container-toolkit;
in
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

  hardware.nvidia-container-toolkit = {
    enable = true;
    mount-nvidia-executables = true;
  };

  # Create symlinks so nvidia-container-runtime can find required binaries and libraries
  systemd.tmpfiles.rules = [
    "L+ /usr/bin/nvidia-ctk - - - - ${lib.getExe' nvidia-container-toolkit "nvidia-ctk"}"
    # "d /usr/lib 0755 root root - -"
    # "L+ /usr/lib/libcuda.so - - - - ${pkgs.linuxPackages.nvidia_x11}/lib/libcuda.so"
    # "L+ /usr/lib/libcuda.so.1 - - - - ${pkgs.linuxPackages.nvidia_x11}/lib/libcuda.so.1"
  ];

  # nvidia-container-runtime config - needed for legacy mode to inject LD_LIBRARY_PATH
  # environment.etc."nvidia-container-runtime/config.toml" = {
  #   text = ''
  #     disable-require = false

  #     [nvidia-container-cli]
  #     ldconfig = "@${lib.getExe' pkgs.glibc.bin "ldconfig"}"
  #     path = "${lib.getExe' pkgs.libnvidia-container "nvidia-container-cli"}"

  #     [nvidia-container-runtime]
  #     mode = "legacy"
  #     runtimes = ["${pkgs.runc}/bin/runc"]

  #     [nvidia-container-runtime.discovery]
  #     lib-root = "/usr/lib"

  #     [nvidia-container-runtime-hook]
  #     path = "${lib.getOutput "tools" pkgs.nvidia-container-toolkit}/bin/nvidia-container-runtime-hook"

  #     [nvidia-ctk]
  #     path = "${lib.getExe' pkgs.nvidia-container-toolkit "nvidia-ctk"}"
  #   '';
  # };

  sops.secrets."k3s/token" = {
    owner = "root";
  };

  services.k3s = {
    enable = true;
    package = inputs.self.lib.k3s { inherit pkgs; };
    role = "agent";
    tokenFile = "/run/secrets/k3s/token";
    serverAddr = "https://tpi01.lan:6443";
    extraFlags = toString [
      "--node-name ${config.networking.hostName}"
      # "--nonroot-devices"
    ];
    # https://github.com/NVIDIA/k8s-device-plugin/issues/1220
    # nvidia-ctk runtime configure --runtime=containerd
    # cat /var/lib/rancher/k3s/agent/etc/containerd/config.toml
    containerdConfigTemplate = ''
      {{ template "base" . }}

      [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.nvidia]
        privileged_without_host_devices = false
        runtime_engine = ""
        runtime_root = ""
        runtime_type = "io.containerd.runc.v2"

      [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.nvidia.options]
        BinaryName = "${nvidia-container-toolkit.tools}/bin/nvidia-container-runtime"

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
