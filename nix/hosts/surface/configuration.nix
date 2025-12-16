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
    # outputs.nixosModules.common
    # outputs.nixosModules.hyprland
    # outputs.nixosModules.users
    # outputs.nixosModules.ssh
    # outputs.nixosModules.builderArm
    # outputs.nixosModules.builderX86
    # outputs.nixosModules.laptops
    # outputs.nixosModules.homeManager
    # outputs.nixosModules.stylix
  ]
  ++ (with inputs.self.nixosModules; [
    ssh
    users
    host-shared
    stylix
    fonts
    builder-arm
    builder-x86
    sops
    locale
  ]);

  # for minecraft i think
  xdg.portal.enable = false;
  services.flatpak.enable = false;

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
