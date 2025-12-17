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
    rpi-common
    k3s-agent
    # partition-syncer
  ]);

  networking.hostName = "tpi03";
  system.stateVersion = "24.11"; # Did you read the comment?
}
