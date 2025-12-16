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
    # sd-image-config
    # rpi-minimal-firmware
  ];

  # Enable minimal firmware to save ~1.3MB on /boot/firmware
  # boot.loader.raspberryPi.useMinimalFirmware = false;

  networking.hostName = "pi01";
  system.stateVersion = "25.11"; # Did you read the comment?
}
