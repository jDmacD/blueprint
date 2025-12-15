{
  config,
  lib,
  pkgs,
  ...
}:
{
  # Limit boot generations due to 128MB boot partition
  # Each generation is ~48MB, so limit to 2 (default + 1 old)
  # This prevents "No space left on device" errors during deployment
  boot.loader.generic-extlinux-compatible.configurationLimit = 2;

  environment.systemPackages = with pkgs; [
    raspberrypi-eeprom
    git
    nfs-utils
  ];
}
