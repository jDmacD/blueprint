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
    builder-arm
    builder-user
    sops
    nvidia
    sunshine
    locale
    github-runner
    # home-assistant
    acme
    steam
    desktop-headless
    hyprland-headless
  ]);

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
    enp3s0.useDHCP = false; # Physical interface has no IP (part of bridge)
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

  # Headless Hyprland session for Sunshine streaming
  services.hyprland-headless = {
    enable = true;
    user = "jmacdonald";
  };

  virtualisation.docker.daemon.settings = {
    "hosts" = [
      "unix:///var/run/docker.sock"
      "tcp://0.0.0.0:2375"
    ];
  };
  system.stateVersion = "25.11"; # Did you read the comment?
}
