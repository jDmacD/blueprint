{ pkgs, inputs, ... }:

{
  # Import both modules unconditionally
  imports = [
    inputs.sops-nix.nixosModules.sops
    inputs.sops-nix.darwinModules.sops
  ];
  
  # Configure sops
  sops.defaultSopsFile = ../secrets.yaml;
  sops.defaultSopsFormat = "yaml";
}