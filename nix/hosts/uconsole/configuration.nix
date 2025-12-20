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
    inputs.nixos-raspberrypi.nixosModules.raspberry-pi-4.base
    inputs.nixos-raspberrypi.nixosModules.raspberry-pi-4.bluetooth
    inputs.oom-hardware.nixosModules.uc.kernel
    inputs.oom-hardware.nixosModules.uc.configtxt
    inputs.oom-hardware.nixosModules.uc.base-cm4
    (lib.mkAliasOptionModule [ "environment" "checkConfigurationOptions" ] [ "_module" "check" ])
  ]
  ++ (with inputs.self.nixosModules; [
    host-shared
    locale
    ssh
    users
    sops
  ]);

  disabledModules = [ (modulesPath + "/rename.nix") ];
  # END:
  boot.loader.raspberryPi.bootloader = "kernel"; # default for new installation
  boot.consoleLogLevel = 7;
  users.users.root.initialPassword = ""; # FIXME
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
    gitMinimal
  ];

  networking.hostName = "uconsole";
  system.stateVersion = "26.05"; # Did you read the comment?
}
