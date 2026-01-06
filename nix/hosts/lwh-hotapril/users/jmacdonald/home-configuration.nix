{
  inputs,
  ...
}:
{

  imports = with inputs.self.homeModules; [
    home-shared
    work
    kubernetes-utils
    git-utils
    terminals
    shells
    terminal-utils
    ai-utils
    dev-utils
    nix-utils
    # cloud-utils
    sops
    editors
    desktop
  ];

  home.stateVersion = "25.11";
}
