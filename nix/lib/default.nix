{ flake, inputs, ... }:
{
  # K3s package configuration
  k3s = import ./k3s.nix;

  # Helper for creating Raspberry Pi host configurations
  # This is a function that needs to be imported with { inputs, flake }
  rpi-host = ./rpi-host.nix;

  # Default SOPS configuration
  # This is a function that needs to be imported with { }
  sops = ./sops.nix;

  # Default Stylix theme configuration
  # This is a function that needs to be imported with { pkgs }
  stylix = ./stylix.nix;

  wallpapers = ./wallpapers.nix; # { inherit pkgs; }

  greetd = ./greetd.nix;
}
