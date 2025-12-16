# Minimal Raspberry Pi firmware package that only includes DTBs for specific board
# This reduces /boot/firmware usage by ~1.3MB by excluding unnecessary device tree files
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.boot.loader.raspberryPi;

  # Map variant to required DTB files
  requiredDtbs = {
    "4" = [
      "bcm2711-rpi-4-b.dtb"
      "bcm2711-rpi-cm4.dtb" # Include CM4 for compatibility
    ];
    "5" = [
      "bcm2712-rpi-5-b.dtb"
      "bcm2712-rpi-cm5-cm5io.dtb" # Include CM5 for compatibility
    ];
  };

  # Create filtered firmware package
  minimalFirmware = pkgs.runCommand "raspberrypi-firmware-minimal-${cfg.variant}" { } ''
    # Copy entire firmware package structure
    cp -r ${pkgs.raspberrypifw}/share $out

    # Remove all DTB files
    rm -f $out/raspberrypi/boot/*.dtb

    # Copy back only required DTB files for this variant
    ${lib.concatMapStringsSep "\n" (dtb: ''
      if [ -f ${pkgs.raspberrypifw}/share/raspberrypi/boot/${dtb} ]; then
        cp ${pkgs.raspberrypifw}/share/raspberrypi/boot/${dtb} $out/raspberrypi/boot/
      fi
    '') (requiredDtbs.${cfg.variant} or [ ])}

    echo "Minimal firmware package created with DTBs for Raspberry Pi ${cfg.variant}"
  '';

in
{
  options = {
    boot.loader.raspberryPi.useMinimalFirmware = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Use minimal firmware package that only includes device tree blobs
        for the specific Raspberry Pi variant.

        This reduces /boot/firmware usage by ~1.3MB but means the SD card
        cannot be moved between different Raspberry Pi models.
      '';
    };
  };

  config = lib.mkIf (cfg.enable && config.boot.loader.raspberryPi.useMinimalFirmware) {
    boot.loader.raspberryPi.firmwarePackage = lib.mkForce minimalFirmware;
  };
}
