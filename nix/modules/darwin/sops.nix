{ inputs, ... }:

{
  imports = [
    inputs.sops-nix.darwinModules.sops
  ];

  # Configure sops
  sops = import ../../lib/sops.nix { };

}
