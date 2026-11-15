# Plain GPT + ext4 (no LVM, unlike worf) so a clone on a bigger server type
# can grow its root on first boot with boot.growPartition + autoResize.
#
# Partitions use /dev/sdaN, not disko's default /dev/disk/by-partlabel/...:
# in nixos-anywhere's kexec installer the by-partlabel symlink was sometimes
# missing when mkfs ran (2 of 4 installs failed on 2026-11-15). Hetzner Cloud
# always presents this disk as /dev/sda.
{ lib, ... }:
{
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
}
