{ pkgs, inputs, ... }:
{

  imports = [
    inputs.stylix.nixosModules.stylix
  ];

  stylix = import ../../lib/stylix.nix { inherit pkgs; };
}
