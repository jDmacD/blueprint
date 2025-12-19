{ pkgs, inputs, ... }:
{

  imports = with inputs.self.homeModules; [
    home-shared
    personal
    kubernetes-utils
    git-utils
    terminals
    shells
    terminal-utils
    ai-utils
    dev-utils
    nix-utils
    sops
    nixvim
    rpi-utils
    hyprland
  ];

  home.stateVersion = "24.05";
}
