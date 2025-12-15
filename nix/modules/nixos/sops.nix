{ inputs, ... }:

{
  imports = [
    inputs.sops-nix.nixosModules.sops
  ];

  # Configure sops
  sops.defaultSopsFile = ../../hosts/secrets.yaml;
  sops.defaultSopsFormat = "yaml";
}
