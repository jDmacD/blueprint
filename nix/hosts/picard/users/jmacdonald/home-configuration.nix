{ pkgs, inputs, ... }:
{

  imports = with inputs.self.homeModules; [
    home-shared
    personal
    kubernetes-utils
    git-utils
    terminals
    terminal-utils
    nix-utils
    sops
  ];

  home.stateVersion = "24.05";
}
