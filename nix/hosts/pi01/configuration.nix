{
  inputs,
  lib,
  pkgs,
  config,
  perSystem,
  ...
}:
{
  imports = [
    ../../modules/nixos/host-shared.nix
    ../../modules/nixos/ssh.nix
    ../../modules/nixos/users.nix
    ../../modules/nixos/rpi-common.nix
    ../../modules/nixos/k3s-agent.nix
  ]
  ++ (with inputs.self.nixosModules; [
    # rpi4-hardware-configuration
    # host-shared
    # ssh
    # users
    # rpi-common
  ]);

  system.nixos.tags = let
    cfg = config.boot.loader.raspberryPi;
  in [
    "raspberry-pi-${cfg.variant}"
    cfg.bootloader
    config.boot.kernelPackages.kernel.version
  ];

  boot = {
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

  sops.defaultSopsFile = ../secrets.yaml;
  sops.defaultSopsFormat = "yaml";
  sops.secrets."k3s/token" = {
    owner = "root";
  };
  networking.hostName = "pi01";
  system.stateVersion = "24.05"; # Did you read the comment?
}
