# nix/hosts/picard/configuration.nix
{
  inputs,
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ./disk-configuration.nix
    ./nfs.nix
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
    inputs.disko.nixosModules.disko
    inputs.nixvirt.nixosModules.default
  ]
  ++ (with inputs.self.nixosModules; [
    ssh
    users
    host-shared
    k3s-agent-gpu
    docker
    sops
    nvidia
    sunshine
    locale
    # github-runner
    # home-assistant
    forgejo-runner
    acme
    desktop
    # openclaw
  ])
  ++ [
    inputs.crann.modules.nixos.steam
    inputs.crann.modules.nixos.remote-builder
  ];

  crann.steam.enable = true;

  # picard is both a client of worf (arm builds) and a server for surface
  # (x86 builds) — see crann.remote-builder's module comment for why both
  # roles can coexist on one host. Same shared builder_ed25519 keypair as
  # surface: this is the client half; server.authorizedKeys below is the
  # matching public key, already committed in blueprint's history before
  # this migration (it isn't sensitive — public keys aren't secrets).
  sops.secrets."builder_ed25519" = {
    owner = "root";
    mode = "0600";
  };
  crann.remote-builder.enable = true;
  crann.remote-builder.machines = [
    {
      hostName = "worf.jtec.xyz";
      system = "aarch64-linux";
      sshKey = config.sops.secrets."builder_ed25519".path;
      maxJobs = 1;
      speedFactor = 2;
      supportedFeatures = [
        "nixos-test"
        "benchmark"
        "big-parallel"
        "kvm"
      ];
    }
  ];
  crann.remote-builder.server.enable = true;
  crann.remote-builder.server.authorizedKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDnim/f3xwmFw/DB9zeHtQSr9i2uKxwsiXkEgE2FdFcY root@picard"
  ];

  # Signs everything picard builds locally, so it can serve as a substituter
  # for other hosts (ssh-ng://picard.lan) without "not signed by any of the
  # keys in trusted-public-keys" warnings. Matching public key goes into the
  # consuming host's trusted-public-keys (e.g. surface's user nix.conf).
  sops.secrets."nix_store_signing_key" = {
    owner = "root";
    mode = "0600";
  };
  nix.settings.secret-key-files = [ config.sops.secrets."nix_store_signing_key".path ];

  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = true;
      swtpm.enable = true;
    };
  };
  networking.bridges = {
    "vmbr0" = {
      interfaces = [ "enp3s0" ];
    };
  };

  networking.interfaces = {
    vmbr0.useDHCP = true; # Bridge gets IP via DHCP
    enp3s0 = {
      useDHCP = false; # Physical interface has no IP (part of bridge)
      wakeOnLan.enable = true;
    };
  };
  boot = {
    loader = {
      systemd-boot = {
        enable = true;
        memtest86.enable = true;
      };
      efi.canTouchEfiVariables = true;
    };
  };

  hardware = {
    enableAllFirmware = true;
    enableRedistributableFirmware = true;
  };

  networking = {
    hostName = "picard";
    useDHCP = false; # Required for bridge configuration
    networkmanager.enable = false; # Disable NetworkManager for bridge setup
    firewall = {
      checkReversePath = false;
      enable = true;
      allowedTCPPorts = [
        22
        111
        2049
        1110
        4045
        5432
      ];
      allowedUDPPorts = [
        9
        111
        2049
        1110
        4045
      ];
    };
  };

  environment.systemPackages = with pkgs; [
    git
  ];

  virtualisation.docker.daemon.settings = {
    "hosts" = [
      "unix:///var/run/docker.sock"
      "tcp://0.0.0.0:2375"
    ];
  };

  # systemd-udevd has leaked to ~26GB RSS here twice (2026-08-09, 2026-08-16),
  # driven by heavy ephemeral veth/lxc churn from docker/k3s/cilium. It runs
  # with OOMScoreAdjust=-1000 (immune to the global OOM killer), so an
  # unbounded leak makes the kernel kill real k3s workloads instead of the
  # actual offender. A cgroup MemoryMax forces a memcg-scoped OOM kill (which
  # bypasses OOMScoreAdjust) well before that point; Restart=always (upstream
  # default) then brings it straight back up.
  systemd.services.systemd-udevd.serviceConfig = {
    MemoryHigh = "1500M";
    MemoryMax = "2G";
  };

  system.stateVersion = "25.11"; # Did you read the comment?
}
