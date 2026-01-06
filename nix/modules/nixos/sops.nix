{
  inputs,
  lib,
  hostName,
  ...
}:

{
  imports = [
    inputs.sops-nix.nixosModules.sops
  ];

  # Configure sops
  sops = import inputs.self.lib.sops { };

}
