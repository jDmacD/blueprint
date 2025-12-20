{ pkgs, inputs, ... }:
{

  imports = [
    inputs.stylix.nixosModules.stylix
  ];

  stylix = import inputs.self.lib.stylix.nix { inherit pkgs; };
}
