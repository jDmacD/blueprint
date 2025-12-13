{
  config,
  lib,
  pkgs,
  ...
}:
{
  environment.systemPackages = with pkgs; [
    raspberrypi-eeprom
    git
    nfs-utils
  ];
}
