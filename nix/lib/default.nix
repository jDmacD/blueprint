{ flake, inputs, ... }:
{
  # K3s package configuration
  k3s = import ./k3s.nix;

  # Helper for creating Raspberry Pi host configurations
  mkRpiHost = import ./rpi-host.nix { inherit inputs flake; };

  # Default SOPS configuration
  sops = import ./sops.nix { };

  # Default Stylix theme configuration
  stylix = import ./stylix.nix;
}
