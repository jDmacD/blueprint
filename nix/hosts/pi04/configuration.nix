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

  networking.hostName = "pi04";
  system.stateVersion = "25.05"; # Did you read the comment?
}
