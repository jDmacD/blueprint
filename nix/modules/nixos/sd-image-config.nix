# SD Image configuration for Raspberry Pi hosts
# Increases boot partition size to prevent "No space left on device" errors
{
  config,
  lib,
  pkgs,
  ...
}:
{
  # Configure SD image with larger boot partition
  # Default in nixos-raspberrypi is 1024MB, but older configs may override this
  sdImage = {
    # Set firmware (boot) partition to 512MB
    # This gives plenty of room for multiple generations and kernel updates
    # while not being excessive
    firmwareSize = 512;
  };
}
