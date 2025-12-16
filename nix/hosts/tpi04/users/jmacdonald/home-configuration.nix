{ pkgs, inputs, ... }:
{

  imports = with inputs.self.homeModules; [
    rpi-common
  ];

  home.stateVersion = "25.11"; # initial home-manager state
}
