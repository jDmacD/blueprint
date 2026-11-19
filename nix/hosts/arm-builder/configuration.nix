# Image for temporary aarch64 build servers (Hetzner CAX, Scaleway BASIC2-A).
# See
# nix/modules/nixos/ephemeral-builder.nix.
{ inputs, ... }:
{
  imports = [ inputs.self.nixosModules.ephemeral-builder ];

  # Hetzner's and Scaleway's arm64 servers boot UEFI.
  boot.loader.grub = {
    efiSupport = true;
    efiInstallAsRemovable = true;
  };
  # Both are QEMU virt machines with a PL011 serial console, which is what
  # the providers' web consoles show.
  boot.kernelParams = [ "console=ttyAMA0,115200" ];

  networking.hostName = "arm-builder";
  nixpkgs.hostPlatform = "aarch64-linux";
}
