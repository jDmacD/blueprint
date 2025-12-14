{ pkgs, inputs, ... }:
{

  imports = with inputs.self.homeModules; [
    home-shared
    terminal-utils
    sops
  ];

  home.stateVersion = "25.11"; # initial home-manager state
}
