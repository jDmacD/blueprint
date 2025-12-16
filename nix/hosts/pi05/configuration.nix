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
    disko
  ]);

  environment.etc."disko/configuration.nix" = {
    text = builtins.readFile ./disk-configuration.nix;
  };

  networking.hostName = "pi05";
  system.stateVersion = "25.05"; # Did you read the comment?
}
