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
    firefox
    vscode
    sops
  ];

  home.stateVersion = "24.05";
}
