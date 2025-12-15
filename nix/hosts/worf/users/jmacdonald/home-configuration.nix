{ pkgs, inputs, ... }:
{

  imports = with inputs.self.homeModules; [
    home-shared
    terminal-utils
    sops
    nix-utils
  ];

  home.stateVersion = "25.11"; # initial home-manager state
}
