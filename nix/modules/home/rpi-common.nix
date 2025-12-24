{ pkgs, inputs, ... }:
{

  imports = with inputs.self.homeModules; [
    shells
    home-shared
  ];

}
