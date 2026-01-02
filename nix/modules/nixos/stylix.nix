{ pkgs, inputs, ... }:
{

  imports = [
    inputs.stylix.nixosModules.stylix
  ];

  stylix = import inputs.self.lib.stylix { inherit pkgs inputs; };

}
