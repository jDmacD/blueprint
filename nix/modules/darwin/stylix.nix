{ pkgs, inputs, ... }:
{

  imports = [
    inputs.stylix.darwinModules.stylix
  ];

  stylix = import ../../lib/stylix.nix { inherit pkgs inputs; };
}
