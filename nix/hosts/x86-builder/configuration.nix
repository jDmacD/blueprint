# Image for temporary x86_64 build servers (Hetzner CX/CPX/CCX), kept as
# insurance: for heavy rebuilds that shouldn't load picard (the GPU and media
# node, capped at 4 jobs since the 2026-10-30 hang), or when picard is down.
# See nix/modules/nixos/ephemeral-builder.nix.
{ inputs, ... }:
{
  imports = [ inputs.self.nixosModules.ephemeral-builder ];

  # Hetzner's x86 servers boot legacy BIOS: grub goes into the EF02
  # partition (disko sets boot.loader.grub.devices from it).

  networking.hostName = "x86-builder";
  nixpkgs.hostPlatform = "x86_64-linux";
}
