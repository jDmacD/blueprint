# Disko configuration with LUKS encryption and TPM2 auto-unlock
# Based on disko luks-btrfs-subvolumes example
# Compatible with lanzaboote (Secure Boot) and TPM modules
# Includes fixes from: https://discourse.nixos.org/t/tpm2-luks-unlock-not-working/52342
{
  lib,
  config,
  ...
}:
{
  disko.devices = {
    disk.main = {
      device = lib.mkDefault "/dev/nvme0n1";
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          # ESP partition for UEFI/Secure Boot
          esp = {
            name = "ESP";
            size = "512M";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
            };
          };
          # LUKS encrypted partition
          luks = {
            size = "100%";
            content = {
              type = "luks";
              name = "crypted";
              # Initial setup: use password or keyfile
              # After first boot, enroll TPM2 using:
              #   sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=0+7 /dev/nvme0n1p2
              settings = {
                allowDiscards = true;
              };
              content = {
                type = "btrfs";
                extraArgs = [ "-f" ];
                subvolumes = {
                  # Root subvolume
                  "/root" = {
                    mountpoint = "/";
                    mountOptions = [
                      "compress=zstd"
                      "noatime"
                    ];
                  };
                  # Home subvolume
                  "/home" = {
                    mountpoint = "/home";
                    mountOptions = [
                      "compress=zstd"
                      "noatime"
                    ];
                  };
                  # Nix store subvolume
                  "/nix" = {
                    mountpoint = "/nix";
                    mountOptions = [
                      "compress=zstd"
                      "noatime"
                    ];
                  };
                  # Swap subvolume
                  "/swap" = {
                    mountpoint = "/.swapvol";
                    swap.swapfile.size = "8G";
                  };
                };
              };
            };
          };
        };
      };
    };
  };

  # Boot configuration for TPM2-LUKS auto-unlock
  boot = {
    # Enable systemd in initrd (required for TPM2-LUKS auto-unlock)
    initrd = {
      # Enable TPM kernel module
      availableKernelModules = [ "tpm_tis" ];

      systemd = {
        enable = true;
        # Enable TPM2 support in initrd
        enableTpm2 = true;

        # Critical: Add missing systemd units for TPM2
        # Without these, TPM2 device may not be initialized properly during boot
        # See: https://discourse.nixos.org/t/tpm2-luks-unlock-not-working/52342
        additionalUpstreamUnits = [ "systemd-tpm2-setup-early.service" ];
        storePaths = [
          "${config.boot.initrd.systemd.package}/lib/systemd/systemd-tpm2-setup"
          "${config.boot.initrd.systemd.package}/lib/systemd/system-generators/systemd-tpm2-generator"
        ];
      };

      # Configure LUKS device for TPM2 auto-unlock
      # After first boot and enrolling TPM2, this will automatically unlock the disk
      # when the system boot chain (PCR 0+7) matches the enrolled measurements
      luks.devices."crypted" = {
        # This will be /dev/nvme0n1p2 after partitioning
        device = "/dev/disk/by-partlabel/disk-main-luks";

        # TPM2 unlock options
        # PCR 0: Firmware code and configuration
        # PCR 7: Secure Boot state
        crypttabExtraOpts = [
          "tpm2-device=auto"
          "tpm2-pcrs=0+7"
        ];

        # Allow TRIM/discard for SSDs
        allowDiscards = true;
      };
    };
  };
}
