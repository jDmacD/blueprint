{ flake, inputs, ... }:
{
  # Default SOPS configuration
  # This is a function that needs to be imported with { }
  sops = ./sops.nix;

  wallpapers = ./wallpapers.nix; # { inherit pkgs; }
}
