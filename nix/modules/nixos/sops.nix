{
  inputs,
  lib,
  hostName,
  ...
}:

{
  imports = lib.optionals (inputs ? sops-nix) [
    inputs.sops-nix.nixosModules.sops
  ];

  # Configure sops - use personal flake's lib if available, otherwise use defaults
  sops =
    if (inputs.self ? lib.sops) then
      import inputs.self.lib.sops { }
    else
      {
        defaultSopsFormat = "yaml";
        # defaultSopsFile will need to be set in the host configuration
      };

}
