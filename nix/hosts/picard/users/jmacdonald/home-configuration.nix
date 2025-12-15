{ pkgs, inputs, ... }:
{

  imports = with inputs.self.homeModules; [
    home-shared
    terminal-utils
    personal
    kubernetes-utils
    git-utils
    terminals
    terminal-utils
    sops
  ];

  home.stateVersion = "24.05";
}
