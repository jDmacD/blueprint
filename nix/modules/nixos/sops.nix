{ pkgs, inputs, lib, ... }:

{
  # Only import the appropriate module based on the system type
  imports = lib.optional (pkgs.stdenv.hostPlatform.isLinux) inputs.sops-nix.nixosModules.sops
         ++ lib.optional (pkgs.stdenv.hostPlatform.isDarwin) inputs.sops-nix.darwinModules.sops;
  
  # Configure sops
  sops.defaultSopsFile = ../secrets.yaml;
  sops.defaultSopsFormat = "yaml";
}