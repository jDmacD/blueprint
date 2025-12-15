{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
{

  imports = with inputs.self.nixosModules; [
    host-shared
    locale
    ssh
    users
    sops
  ];

  boot = {
    # Limit boot generations due to 128MB boot partition
    # Each generation is ~48MB, so limit to 2 (default + 1 old)
    # This prevents "No space left on device" errors during deployment
    loader.generic-extlinux-compatible.configurationLimit = 2;
    kernelModules = [ "rbd" ];
    kernelParams = [
      "cgroup_enable=cpuset"
      "cgroup_memory=1"
      "cgroup_enable=memory"
    ];
    kernelPatches = [
      {
        name = "custom-kernel-config";
        patch = null;
        extraConfig = ''
          ARM64_VA_BITS_47 n
          ARM64_VA_BITS_48 y
          ARM64_VA_BITS 48
          PGTABLE_LEVELS 4
        '';
      }
    ];
  };

  environment.systemPackages = with pkgs; [
    raspberrypi-eeprom
    git
    nfs-utils
  ];
}
