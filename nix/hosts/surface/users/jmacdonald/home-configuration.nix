{
  pkgs,
  config,
  inputs,
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
      network-utils
      cloud-utils
      sops
      editors
      rpi-utils
      desktop
    ]
    ++ [
      # niri's home config is provided by the crann NixOS module
      # (inputs.crann.modules.nixos.niri) via home-manager.sharedModules;
      # importing the standalone home module here too would double-declare
      # programs.niri.*. Only the standalone (non-NixOS) case imports it.
      inputs.crann.modules.homeManager.noctalia
    ];

  programs.claude-code.preset = "home";

  # programs.noctalia-shell.wallpaper.monitorDirectories = [
  #   {
  #     name = "eDP-1";
  #     dimensions = "3000x2000";
  #     wallpaper = "wallhaven-n6kwqx_3000x2000.png";
  #   }
  # ];

  home.packages = with pkgs; [
    # blender
    # inkscape
  ];

  home.stateVersion = "24.05";
}
