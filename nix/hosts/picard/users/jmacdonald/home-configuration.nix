{
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
    sops
    editors
    rpi-utils
    desktop
  ];

  home.stateVersion = "24.05";
}
