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
    # inputs.sops-nix.nixosModules.sops
    # outputs.nixosModules.common
    # outputs.nixosModules.users
    # outputs.nixosModules.ssh
    # outputs.nixosModules.gatus
    # outputs.nixosModules.bedrock
  ];

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

  users.users.arm64builder = {
    isNormalUser = true;
    createHome = false;
    group = "arm64builder";

    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDnim/f3xwmFw/DB9zeHtQSr9i2uKxwsiXkEgE2FdFcY root@picard"
    ];
  };
  users.groups.arm64builder = { };
  nix.settings.trusted-users = [ "arm64builder" ];

  sops.defaultSopsFile = ../secrets.yaml;
  sops.defaultSopsFormat = "yaml";
  sops.secrets."docker-gatus/.dockerenv" = {
    owner = "root";
  };

  networking.hostName = "worf";
  systemd.network.networks."10-wan".address = [
    "37.27.34.153"
    "2a01:4f9:c010:9195::/64"
  ];

  system.stateVersion = "24.05"; # Did you read the comment?
}
