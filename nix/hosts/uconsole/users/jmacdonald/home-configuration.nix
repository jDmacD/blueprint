{ pkgs, inputs, ... }:
{

  imports = with inputs.self.homeModules; [
    rpi-common
    home-shared
    # personal
    kubernetes-utils
    # git-utils
    terminals
    shells
    terminal-utils
    dev-utils
    # nix-utils
    sops
    editors
  ];

  home.stateVersion = "25.05"; # initial home-manager state
}
