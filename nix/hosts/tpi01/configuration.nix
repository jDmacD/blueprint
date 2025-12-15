{
  inputs,
  lib,
  pkgs,
  config,
  ...
}:
{
  imports = [
    ./disk-configuration.nix
  ]
  ++ (with inputs.self.nixosModules; [
    host-shared
    ssh
    users
    rpi-common
    k3s-server
  ]);

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
  networking.hostName = "tpi01";
  system.stateVersion = "24.11"; # Did you read the comment?
}
