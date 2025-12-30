# Example to create a bios compatible gpt partition
{ ... }:
{
  systemd.tmpfiles.rules = [
    # Type Path        Mode    UID     GID     Age  Argument
    "d /spinner        0755    1002    100     -    -"
  ];
  disko.devices = {
    disk.steam = {
      type = "disk";
      device = "/dev/nvme0n1";
      content = {
        type = "gpt";
        partitions = {
          games = {
            size = "100%";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/steam";
            };
          };
        };
      };
    };
    disk.main = {
      type = "disk";
      device = "/dev/nvme1n1";
      content = {
        type = "gpt";
        partitions = {
          boot = {
            size = "1M";
            type = "EF02"; # for grub MBR
          };
          ESP = {
            size = "512M";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
            };
          };
          root = {
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
    # 6TB WD drives in btrfs RAID 0
    disk.sda = {
      type = "disk";
      device = "/dev/sda";
      content = {
        type = "gpt";
        partitions = {
          storage = {
            size = "100%";
          };
        };
      };
    };
    disk.sdb = {
      type = "disk";
      device = "/dev/sdb";
      content = {
        type = "gpt";
        partitions = {
          storage = {
            size = "100%";
            content = {
              type = "btrfs";
              extraArgs = [
                "-f"
                "-d"
                "raid0"
                "-m"
                "raid0"
                "/dev/sda1"
              ];
              subvolumes = {
                "/storage" = {
                  mountpoint = "/spinner";
                  mountOptions = [ "noatime" ];
                };
              };
            };
          };
        };
      };
    };
  };
}
