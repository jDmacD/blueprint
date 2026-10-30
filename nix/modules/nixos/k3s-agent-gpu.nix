{
  config,
  lib,
  pkgs,
  inputs,
  perSystem,
  ...
}:
# k3s agent with NVIDIA GPU support. k3s itself comes from crann's k3s module
# (package pinned through nixpkgs-multiverse by crann.k3s.version, kubelet
# memory eviction, firewall ports, Ceph prerequisites), as on the nix-pi
# fleet. The GPU wiring below (nvidia-container-toolkit from nixpkgs-25-11,
# the nvidia containerd runtime) stays local; crann's k3s-nvidia is not used
# yet, see docs/systems/gpu.md in catalogue for why the toolkit is pinned.
let
  nvidia-container-toolkit = perSystem.nixpkgs-25-11.nvidia-container-toolkit;
in
{
  imports = [ inputs.crann.modules.nixos.k3s ];

  # crann.k3s turns the firewall off at normal priority; picard's
  # configuration.nix enables it, so force it here.
  networking.firewall.enable = lib.mkForce false;

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

  crann.k3s = {
    enable = true;
    role = "agent";
    serverAddr = "https://tpi01.lan:6443";
    tokenFile = config.sops.secrets."k3s/token".path;
  };

  services.k3s = {
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

  environment.systemPackages = with pkgs; [
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
