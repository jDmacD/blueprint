# Image for temporary x86_64 build servers (Hetzner CX/CPX/CCX), kept as
# insurance: for heavy rebuilds that shouldn't load picard (the GPU and media
# node, capped at 4 jobs since the 2026-10-30 hang), or when picard is down.
# See nix/modules/nixos/ephemeral-builder.nix.
{ inputs, ... }:
{
  imports = [ inputs.self.nixosModules.ephemeral-builder ];

  # Hetzner's x86 types don't all boot the same way: a cx33 clone booted
  # legacy BIOS, but a cpx62 clone of the same BIOS-only image never came up
  # (2026-11-15), so install both. grub goes into the EF02 partition for BIOS
  # (disko sets boot.loader.grub.devices from it) and to the ESP's removable
  # path for UEFI.
  boot.loader.grub = {
    efiSupport = true;
    efiInstallAsRemovable = true;
  };

  networking.hostName = "x86-builder";
  nixpkgs.hostPlatform = "x86_64-linux";
}
