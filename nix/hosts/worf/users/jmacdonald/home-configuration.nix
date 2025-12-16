{ pkgs, inputs, ... }:
{

  imports = with inputs.self.homeModules; [
    home-shared
    terminal-utils
    sops
    nix-utils
    shells
  ];

  home.stateVersion = "25.11"; # initial home-manager state
}
