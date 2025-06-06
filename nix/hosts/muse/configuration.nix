{
  config,
  lib,
  pkgs,
  inputs,
  outputs,
  ...
}: let
in {
  imports = [
    ./hardware-configuration.nix
    inputs.raspberry-pi-nix.nixosModules.raspberry-pi
  ];

  environment.systemPackages = with pkgs; [
    raspberrypi-eeprom
    git
  ];

  networking = {
    useDHCP = true;
    wireless.enable = false;
  };

  boot = {
    kernelParams = [
      "cgroup_enable=cpuset"
      "cgroup_memory=1"
      "cgroup_enable=memory"
    ];
    kernelModules = ["rbd"];
    kernelPatches = [
      {
        name = "envoy-kernel-config";
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

  raspberry-pi-nix.board = "bcm2712";
  hardware = {
    bluetooth.enable = false;
    raspberry-pi = {
      config = {
        all = {
          base-dt-params = {
            # enable autoprobing of bluetooth driver
            # https://github.com/raspberrypi/linux/blob/c8c99191e1419062ac8b668956d19e788865912a/arch/arm/boot/dts/overlays/README#L222-L224
            krnbt = {
              enable = true;
              value = "on";
            };
          };
        };
      };
    };
  };

  system.stateVersion = "25.05"; # Did you read the comment?
}