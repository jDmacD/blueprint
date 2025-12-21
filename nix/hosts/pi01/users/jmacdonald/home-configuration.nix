{ pkgs, inputs, ... }:
{

  imports = with inputs.self.homeModules; [
    rpi-common
  ];

  home.stateVersion = "25.05"; # initial home-manager state
}
