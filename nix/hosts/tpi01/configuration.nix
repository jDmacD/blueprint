{
  inputs,
  lib,
  pkgs,
  config,
  ...
}:
{
  imports = [
    # ./disk-configuration.nix
  ]
  ++ (with inputs.self.nixosModules; [
    rpi-common
    # k3s-server
    partition-syncer
  ]);

  networking.hostName = "tpi01";
  system.stateVersion = "24.11"; # Did you read the comment?
}
