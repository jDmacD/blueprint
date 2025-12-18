{
  inputs,
  outputs,
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
    stylix
    fonts
    builder-arm
    builder-x86-user
    sops
    nvidia
    locale
    github-runner
  ]);

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
    bluetooth = {
      enable = true; # enables support for Bluetooth
      powerOnBoot = true; # powers up the default Bluetooth controller on boot
      package = pkgs.bluez;
      settings = {
        General = {
          Experimental = true;
        };
      };
    };
    enableAllFirmware = true;
    enableRedistributableFirmware = true;
  };

  services = {
    blueman = {
      enable = true;
    };
    xserver = {
      xkb.layout = "gb";
      xkb.variant = "";
      videoDrivers = [ "nvidia" ];
    };
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
    # Doesn't work with wayland / hyrland
    kmscon = {
      enable = false;
    };
    # solaar = {
    #   enable = true;
    # };
    nfs = {
      server = {
        enable = true;
        exports = ''
          /export *(rw,fsid=0,no_subtree_check)
          /export/calibre-library *(rw,insecure,no_subtree_check)
        '';
      };
    };
  };

  networking = {
    hostName = "picard";
    networkmanager.enable = true;
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
    mangohud
    lutris
    cloudflared
  ];

  virtualisation.docker.daemon.settings = {
    "hosts" = [
      "unix:///var/run/docker.sock"
      "tcp://0.0.0.0:2375"
    ];
  };
  system.stateVersion = "24.05"; # Did you read the comment?
}
