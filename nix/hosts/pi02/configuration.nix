{
  inputs,
  lib,
  pkgs,
  config,
  ...
}:
{
  imports = with inputs.self.nixosModules; [
    rpi-common
    k3s-agent
  ];

  networking.hostName = "pi02";
  system.stateVersion = "24.05"; # Did you read the comment?
}
