{
  inputs,
  outputs,
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}
{
  imports = [
    ./hardware-configuration.nix
    outputs.nixosModules.common
    outputs.nixosModules.hyprland
    outputs.nixosModules.users
    outputs.nixosModules.ssh
    outputs.nixosModules.builderArm
    outputs.nixosModules.builderX86
    outputs.nixosModules.laptops
    outputs.nixosModules.homeManager
    outputs.nixosModules.stylix
  ];

  services.flatpak.enable = true;

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };

  environment = {
    systemPackages = with pkgs; [
      docker-client
      cifs-utils
    ];
    variables = {
      DOCKER_HOST = "tcp://picard.lan:2375";
    };
  };

  networking = {
    hostName = "surface";
    networkmanager.enable = true;
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
    extraHosts = ''
      37.27.34.153 hel-1
    '';
  };

  hardware = {
    bluetooth = {
      enable = true; # enables support for Bluetooth
      powerOnBoot = true; # powers up the default Bluetooth controller on boot
    };
    graphics = {
      # package = mesa;
    };
    enableAllFirmware = true;
  };

  services = {
    xserver = {
      xkb.layout = "gb";
      xkb.variant = "";
    };
    pipewire = {
      enable = true;
      pulse.enable = true;
    };
  };

  system.stateVersion = "24.05"; # Did you read the comment?
}
