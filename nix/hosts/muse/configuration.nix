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
    inputs.self.nixosModules.k3s-server
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
