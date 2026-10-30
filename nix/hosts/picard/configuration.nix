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
      publicHostKey = "c3NoLWVkMjU1MTkgQUFBQUMzTnphQzFsWkRJMU5URTVBQUFBSUdyalVZWDlpdXc2aEw3WXVLSDA3cUFieWs5Z0YxcjFrOEx1UWQwT2ZRaHQK";
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

  networking.interfaces = {
    enp3s0 = {
      useDHCP = true;
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
    useDHCP = false; # DHCP is enabled per-interface (enp3s0)
    networkmanager.enable = false; # scripted networking + dhcpcd
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

  # A local build of picard's own toplevel (nixpkgs bump, max-jobs 16 /
  # cores 0) exhausted RAM on 2026-10-30 and stalled the host in reclaim for
  # 30 min until a hard reset; the OOM killer never fired. Cap the builds so
  # an overrun kills a builder inside nix-daemon's cgroup instead, and leave
  # room for the k3s workloads (31 GiB RAM, zram-only swap).
  nix.settings = {
    max-jobs = 4;
    cores = 4;
  };
  systemd.services.nix-daemon.serviceConfig = {
    MemoryHigh = "12G";
    MemoryMax = "16G";
  };
  # Allow the full Magic SysRq set (REISUB) at the console; NixOS's default
  # of 16 only allows sync, which is all that worked during that hang.
  boot.kernel.sysctl."kernel.sysrq" = 1;

  system.stateVersion = "25.11"; # Did you read the comment?
}
