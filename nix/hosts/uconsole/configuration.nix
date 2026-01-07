{
  inputs,
  lib,
  pkgs,
  config,
  modulesPath,
  ...
}:
{
  imports = [
    (lib.mkAliasOptionModule [ "environment" "checkConfigurationOptions" ] [ "_module" "check" ])
  ]
  ++ (with inputs.oom-hardware-nixos-raspberrypi.nixosModules.raspberry-pi-4; [
    base
    bluetooth
  ])
  ++ (with inputs.oom-hardware.nixosModules.uc; [
    kernel
    configtxt
    base-cm4
  ])
  ++ (with inputs.self.nixosModules; [
    host-shared
    locale
    ssh
    users
    sops
  ]);

  home-manager = {
    extraSpecialArgs = { inherit inputs; };
    users.jmacdonald = ./users/jmacdonald/home-configuration.nix;
  };

  disabledModules = [ (modulesPath + "/rename.nix") ];
  boot.loader.raspberryPi.bootloader = "kernel"; # default for new installation
  boot.consoleLogLevel = 7;
  boot.extraModulePackages = with config.boot.kernelPackages; [
      rtl8812au
    ];

  console = {
    earlySetup = true;
    font = "ter-v32n";
    packages = with pkgs; [ terminus_font ];
  };
  fileSystems = {
    "/boot/firmware" = {
      device = "/dev/disk/by-label/FIRMWARE";
      fsType = "vfat";
      options = [ "noatime" ];
    };
    "/" = {
      device = "/dev/disk/by-label/NIXOS_SD";
      fsType = "ext4";
      options = [ "noatime" ];
    };
  };
  environment.systemPackages = with pkgs; [
    wirelesstools
    iw
    git
  ];
  networking.networkmanager.enable = true;
  networking.hostName = "uconsole";

  systemd.services."serial-getty@ttyS0".enable = false; # there is no serial console? am I right?
  system.stateVersion = config.system.nixos.release;
  system.defaultChannel = "https://nixos.org/channels/nixos-unstable";
}
