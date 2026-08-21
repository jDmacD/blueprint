{
  inputs,
  config,
  pkgs,
  ...
}:
{

  imports = [
    ./hardware-configuration.nix
    ./nfs.nix
  ]
  ++ (with inputs.self.nixosModules; [
    ssh
    users
    host-shared
    sops
    locale
    desktop
    lanzaboote
    tpm
    opendeck
  ])
  ++ [
    inputs.crann.modules.nixos.optnix
    inputs.crann.modules.nixos.remote-builder
  ];

  crann.optnix.enable = true;

  # Dispatches builds to worf (arm) and picard (x86) — both run
  # crann.remote-builder.server. sshKey is the client identity shared across
  # every host in this role; the matching public key is authorized on both
  # servers. publicHostKey is `base64 -w0` of each machine's
  # /etc/ssh/ssh_host_ed25519_key.pub (fetched via ssh-keyscan 2026-08-21) —
  # this is the fix for the reason distributed builds never fully worked
  # here: without it, the non-interactive nix-daemon SSH connection had no
  # known_hosts entry to verify against and silently fell back to local.
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
    {
      hostName = "picard.lan";
      system = "x86_64-linux";
      sshKey = config.sops.secrets."builder_ed25519".path;
      publicHostKey = "c3NoLWVkMjU1MTkgQUFBQUMzTnphQzFsWkRJMU5URTVBQUFBSUVVdXg4NWh3dkpqeXhSNk9meWZheHhEbDdkeWNMbUVmSWJIYXFrQTgxbUcK";
      maxJobs = 10;
      speedFactor = 2;
      supportedFeatures = [
        "nixos-test"
        "benchmark"
        "big-parallel"
      ];
    }
  ];

  environment = {
    systemPackages = with pkgs; [
      docker-client
      cifs-utils
      rpi-imager
    ];
    variables = {
      DOCKER_HOST = "tcp://picard.lan:2375";
    };
    pathsToLink = [
      "/share/applications"
      "/share/xdg-desktop-portal"
    ];
  };

  programs = {
    nix-ld = {
      enable = true;
    };
    # streamcontroller = {
    #   enable = true;
    # };
  };

  networking = {
    hostName = "surface";
    networkmanager.enable = true;
    networkmanager.plugins = with pkgs; [ networkmanager-openvpn ];
    firewall = {
      checkReversePath = false;
      enable = true;
      allowedTCPPorts = [
        53317 # localsend
      ];
      allowedUDPPorts = [
        53317 # localsend
      ];
    };
  };

  hardware = {
    enableAllFirmware = true;
    enableRedistributableFirmware = true;
  };

  system.stateVersion = "24.05"; # Did you read the comment?
}
