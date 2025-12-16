{ pkgs, inputs, ... }:
{

  imports = [
    inputs.stylix.nixosModules.stylix
  ];

  stylix = import ../../lib/stylix-config.nix { inherit pkgs; };
}
