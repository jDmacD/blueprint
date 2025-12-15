{ inputs, ... }:

{
  # Import only the NixOS sops module
  # Darwin hosts should import inputs.sops-nix.darwinModules.sops directly in their configuration
  imports = [
    inputs.sops-nix.nixosModules.sops
  ];

  # Configure sops
  sops.defaultSopsFile = ../../hosts/secrets.yaml;
  sops.defaultSopsFormat = "yaml";
}