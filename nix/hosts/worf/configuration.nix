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
    docker
    docker-bedrock
    sops
    builder-user
    locale
  ]);

  boot = {
    initrd = {
      availableKernelModules = [
        "xhci_pci"
        "virtio_scsi"
        "sr_mod"
      ];
      kernelModules = [ "dm-snapshot" ];
    };
    kernelModules = [ ];
    extraModulePackages = [ ];
  };

  environment.systemPackages = with pkgs; [
    git
  ];

  networking = {
    hostName = "worf";
    domain = "jtec.xyz";
  };

  systemd.network.networks."10-wan".address = [
    "37.27.34.153"
    "2a01:4f9:c010:9195::/64"
  ];

  nixpkgs.hostPlatform = "aarch64-linux";
  system.stateVersion = "24.05"; # Did you read the comment?
}
