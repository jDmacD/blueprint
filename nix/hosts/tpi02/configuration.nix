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
  ]);

  networking.hostName = "tpi02";
  system.stateVersion = "24.11"; # Did you read the comment?
}
