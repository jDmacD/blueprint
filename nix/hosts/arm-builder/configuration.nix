# Image for temporary aarch64 build servers on Hetzner Cloud.
#
# Never deployed as a long-lived host. `nix run .#snapshot-arm-builder`
# installs it onto a throwaway cax11 with nixos-anywhere and saves a snapshot
# labelled role=arm-builder; nix-pi's build-ephemeral boots a large CAX from
# that snapshot for kernel builds and deletes it afterwards.
#
# Deliberately no sops: the snapshot holds no secrets. Every clone shares the
# image's SSH host key, so clients can pin one publicHostKey.
{
  inputs,
  lib,
  modulesPath,
  ...
}:
{
  imports = [
    ./disk-configuration.nix
    (modulesPath + "/profiles/qemu-guest.nix")
    inputs.disko.nixosModules.disko
  ]
  ++ (with inputs.self.nixosModules; [
    ssh
    users
    host-shared
  ])
  ++ [
    inputs.crann.modules.nixos.remote-builder
  ];

  # Same shared builder_ed25519 client key as worf accepts (picard, surface
  # and lwh-hotapril all dispatch with it).
  crann.remote-builder.server.enable = true;
  crann.remote-builder.server.authorizedKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDnim/f3xwmFw/DB9zeHtQSr9i2uKxwsiXkEgE2FdFcY root@picard"
  ];

  boot = {
    loader.grub = {
      efiSupport = true;
      efiInstallAsRemovable = true;
    };
    initrd.availableKernelModules = [
      "xhci_pci"
      "virtio_scsi"
      "sr_mod"
    ];
    # Fill whatever disk the clone's server type has (cax41: 320 GB).
    growPartition = true;
  };
  fileSystems."/".autoResize = true;

  # A clone has a fresh IP each time; DHCP only. IPv6 on Hetzner needs a
  # static address, and the servers are created IPv4-only.
  networking = {
    hostName = "arm-builder";
    useDHCP = false;
  };
  systemd.network = {
    enable = true;
    networks."10-wan" = {
      matchConfig.Name = "en*";
      networkConfig.DHCP = "ipv4";
    };
  };

  # Nothing on it worth keeping; the server is deleted after each run.
  services.fwupd.enable = lib.mkForce false;
  services.udisks2.enable = lib.mkForce false;

  nixpkgs.hostPlatform = "aarch64-linux";
  system.stateVersion = "26.05";
}
