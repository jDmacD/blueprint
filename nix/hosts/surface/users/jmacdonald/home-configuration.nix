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
    network-utils
    cloud-utils
    sops
    editors
    rpi-utils
    desktop
  ];
  programs.claude-code.preset = "home";

  home.packages = with pkgs; [
    # blender
    # inkscape
  ];

  home.stateVersion = "24.05";
}
