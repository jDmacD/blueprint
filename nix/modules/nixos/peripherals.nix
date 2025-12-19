{ pkgs, inputs, ... }:
{

  modules = [
    inputs.solaar.nixosModules.default
  ];

  solaar = {
    enable = true;
  };

}
