{ pkgs, inputs, ... }:
{

  imports = [
    inputs.solaar.nixosModules.default
  ];

  solaar = {
    enable = true;
  };

}
