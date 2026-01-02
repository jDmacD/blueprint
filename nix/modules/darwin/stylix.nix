{ pkgs, inputs, ... }:
{

  imports = [
    inputs.stylix.darwinModules.stylix
  ];

  stylix = import inputs.self.lib.stylix { inherit pkgs inputs; };
}
