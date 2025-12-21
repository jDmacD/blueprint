{ pkgs, inputs, ... }:
{

  imports = with inputs.self.homeModules; [
    rpi-common
    kubernetes-utils
    editors
  ];

  home.stateVersion = "25.05"; # initial home-manager state
}
