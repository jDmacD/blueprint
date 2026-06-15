# Example to create a bios compatible gpt partition
{ pkgs, ... }:
{
  systemd.tmpfiles.rules = [
    # Type Path        Mode    UID     GID     Age  Argument
    "d /spinner        0777    0       0       -    -"
    "Z /spinner        0777    0       0       -    -"
  ];

  # Share the Steam library on /steam between jmacdonald (owner) and sunshine
  # (streaming session) via the `users` group. Default ACLs make new files
  # created by either user group-writable regardless of umask, so Steam/Proton
  # can write compatdata/shadercache from both accounts. The recursive pass only
  # runs once to fix pre-existing files; new files inherit the default ACL.
  system.activationScripts.steamLibraryAcl.text = ''
    if [ -d /steam/SteamLibrary ] && [ ! -e /steam/SteamLibrary/.acl-applied ]; then
      ${pkgs.acl}/bin/setfacl -R    -m g:users:rwX /steam/SteamLibrary
      ${pkgs.acl}/bin/setfacl -R -d -m g:users:rwX /steam/SteamLibrary
      touch /steam/SteamLibrary/.acl-applied
    fi
  '';
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
