{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
{

  imports = [
    ./host-shared.nix
    ./locale.nix
    ./ssh.nix
    ./users.nix
    ./sops.nix
    ./acme.nix
  ];

  boot = {
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
