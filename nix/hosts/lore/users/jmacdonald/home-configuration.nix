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
    editors
    vscode
    firefox
  ];

  home.stateVersion = "25.11"; # initial home-manager state
}
