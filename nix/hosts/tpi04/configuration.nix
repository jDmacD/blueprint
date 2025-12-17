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
    # k3s-agent
    # disko
  ]);

  # environment.etc."disko/configuration.nix" = {
  #   text = builtins.readFile ./disk-configuration.nix;
  # };

  networking.hostName = "tpi04";
  system.stateVersion = "24.11"; # Did you read the comment?
}
