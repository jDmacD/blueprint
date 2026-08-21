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
    locale
    #  eduvpn-server

  ])
  ++ [
    inputs.crann.modules.nixos.remote-builder
  ];

  # worf is server-only — surface and picard both dispatch arm builds here.
  # Same shared builder_ed25519 keypair as the other hosts; no client role
  # (and so no sops secret) needed on this side, just the public half.
  crann.remote-builder.server.enable = true;
  crann.remote-builder.server.authorizedKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDnim/f3xwmFw/DB9zeHtQSr9i2uKxwsiXkEgE2FdFcY root@picard"
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
