{
  pkgs,
  inputs,
  ...
}:
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
    cloud-utils
    network-utils
    sops
    editors
    rpi-utils
    desktop
  ];
  home.packages = with pkgs; [
    pinta
    upscayl
  ];

  home.stateVersion = "25.11";
}
