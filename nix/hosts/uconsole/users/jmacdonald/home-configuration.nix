{ pkgs, inputs, ... }:
{

  imports = with inputs.self.homeModules; [
    rpi-common
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
  ];

  home.stateVersion = "26.05"; # initial home-manager state
}
