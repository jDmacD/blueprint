{ pkgs, inputs, lib, ... }:

{
  # Import both modules unconditionally
  imports = [
    inputs.sops-nix.nixosModules.sops
    inputs.sops-nix.darwinModules.sops
  ];
  
  # Configure sops
  sops.defaultSopsFile = ../secrets.yaml;
  sops.defaultSopsFormat = "yaml";
  
  # Conditionally enable the appropriate module's functionality
  # This works because each module's implementation will check if it's on the right platform
  # and not activate if it's on the wrong one
  nixos.sops = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
    enable = true;
  };
  
  darwin.sops = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
    enable = true;
  };
}