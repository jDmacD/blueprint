{
  pkgs,
  inputs,
  perSystem,
  ...
}:
{

  imports =
    with inputs.self.homeModules;
    [
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
      nixvim
      rpi-utils
      hyprland
    ]
    ++ (with perSystem.self; [
      fleet-deploy
    ]);

  home.stateVersion = "24.05";
}
