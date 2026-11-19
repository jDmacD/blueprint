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
    locale
    # github-runner
    # home-assistant
    forgejo-runner
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

  # Private binary cache on Scaleway Object Storage (bucket jtec-nix-cache,
  # nl-ams, project `ephemeral`). Unlike cachix's free tier it never evicts,
  # so the Pi kernels stay fetchable for rollbacks and images. Pushes come
  # from jmacdonald (nix-pi's build-push), signed with jtec-nix-cache-1 (home
  # sops nix_cache_signing_key); the daemon only reads. The credentials are
  # the `ephemeral` project's key (claude-ephemeral-builder), which can't
  # reach anything outside that project; kept to picard (./secrets.yaml).
  sops.secrets."nix_cache_aws" = {
    sopsFile = ./secrets.yaml;
    owner = "root";
    mode = "0400";
  };
  systemd.services.nix-daemon.environment.AWS_SHARED_CREDENTIALS_FILE =
    config.sops.secrets."nix_cache_aws".path;
  nix.settings = {
    substituters = [ "s3://jtec-nix-cache?endpoint=s3.nl-ams.scw.cloud&region=nl-ams" ];
    trusted-public-keys = [ "jtec-nix-cache-1:jTimDGKpmSD8PAWRS3TZsGl8Yu57ZrlsQ6OHwp6u/L8=" ];
  };

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

  # Hardware watchdog: if systemd stops petting it for 30 s (a hard hang), the
  # chipset resets the machine. Kernel panics already reboot via
  # kernel.panic = 10; this covers hangs that never panic. Uses the PCH TCO
  # watchdog (iTCO_wdt), not the newer intel_oc_wdt, which probes first and so
  # takes /dev/watchdog0. The udev symlink pins it by name, because the
  # watchdogN numbering follows driver probe order.
  services.udev.extraRules = ''
    SUBSYSTEM=="watchdog", ATTR{identity}=="iTCO_wdt", SYMLINK+="watchdog-itco"
  '';
  systemd.settings.Manager = {
    WatchdogDevice = "/dev/watchdog-itco";
    RuntimeWatchdogSec = "30s";
    RebootWatchdogSec = "10min";
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
