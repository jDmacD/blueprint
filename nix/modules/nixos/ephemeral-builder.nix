# Shared config for the images that temporary Hetzner Cloud build servers boot
# from (hosts arm-builder and x86-builder). Neither is ever deployed as a
# long-lived host: `nix run .#snapshot-builder -- <arm|x86>` installs one onto
# a throwaway server with nixos-anywhere and snapshots it, and crann's
# build-ephemeral boots a large server from that snapshot, builds through it
# and deletes it.
#
# Deliberately no sops: the snapshot holds no secrets. Every clone shares the
# image's SSH host key, which snapshot-builder records in the snapshot's
# description for clients to pin.
{
  inputs,
  lib,
  modulesPath,
  ...
}:
{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    inputs.disko.nixosModules.disko
    inputs.crann.modules.nixos.remote-builder
  ]
  ++ (with inputs.self.nixosModules; [
    ssh
    users
    host-shared
  ]);

  # Same shared builder_ed25519 client key as worf accepts (picard, surface
  # and lwh-hotapril all dispatch with it).
  crann.remote-builder.server.enable = true;
  crann.remote-builder.server.authorizedKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDnim/f3xwmFw/DB9zeHtQSr9i2uKxwsiXkEgE2FdFcY root@picard"
  ];

  # Plain GPT + ext4 (no LVM, unlike worf) so a clone on a bigger server type
  # grows its root on first boot. The EF02 partition serves x86's legacy BIOS
  # boot, the ESP arm64's UEFI.
  #
  # Partitions use /dev/sdaN, not disko's default /dev/disk/by-partlabel/...:
  # in nixos-anywhere's kexec installer the by-partlabel symlink was sometimes
  # missing when mkfs ran (2 of 4 installs failed on 2026-11-15). Hetzner Cloud
  # always presents the disk as /dev/sda on both architectures.
  disko.devices.disk.disk1 = {
    device = lib.mkDefault "/dev/sda";
    type = "disk";
    content = {
      type = "gpt";
      partitions = {
        boot = {
          name = "boot";
          size = "1M";
          type = "EF02";
        };
        esp = {
          device = "/dev/sda2";
          name = "ESP";
          size = "500M";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
          };
        };
        root = {
          device = "/dev/sda3";
          name = "root";
          size = "100%";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/";
          };
        };
      };
    };
  };

  boot = {
    initrd.availableKernelModules = [
      "xhci_pci"
      "virtio_scsi"
      "sr_mod"
    ];
    # Fill whatever disk the clone's server type has.
    growPartition = true;
  };
  fileSystems."/".autoResize = true;

  # A clone has a fresh IP each time; DHCP only. IPv6 on Hetzner needs a
  # static address, and the servers are created IPv4-only. The NIC is ens3
  # on x86 and enp1s0 on arm64.
  networking.useDHCP = false;
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

  system.stateVersion = "26.05";
}
