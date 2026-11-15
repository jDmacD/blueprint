# Image for temporary aarch64 build servers (Hetzner CAX). See
# nix/modules/nixos/ephemeral-builder.nix.
{ inputs, ... }:
{
  imports = [ inputs.self.nixosModules.ephemeral-builder ];

  # Hetzner's arm64 servers boot UEFI.
  boot.loader.grub = {
    efiSupport = true;
    efiInstallAsRemovable = true;
  };

  networking.hostName = "arm-builder";
  nixpkgs.hostPlatform = "aarch64-linux";
}
