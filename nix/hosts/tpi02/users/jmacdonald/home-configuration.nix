{ pkgs, inputs, ... }:
{

  imports = with inputs.self.homeModules; [
    home-shared
    sops
  ];

  home.stateVersion = "25.11"; # initial home-manager state
}
