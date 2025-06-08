{
  config,
  lib,
  pkgs,
  inputs,
  outputs,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/host-shared.nix
    ../../modules/nixos/k3s-server.nix
  ];

  environment.systemPackages = with pkgs; [
    raspberrypi-eeprom
    git
  ];

  networking = {
    hostName = "muse";
    useDHCP = true;
    wireless.enable = true;
  };

  system.stateVersion = "25.05"; # Did you read the comment?
}
