{ inputs, ... }:

{
  imports = [
    inputs.sops-nix.nixosModules.sops
  ];

  # Configure sops
  sops = import ../../lib/sops.nix { };

}
