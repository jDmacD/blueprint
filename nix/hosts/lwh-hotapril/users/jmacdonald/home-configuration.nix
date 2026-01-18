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
    network-utils
    ai-utils
    dev-utils
    nix-utils
    # cloud-utils
    sops
    editors
    desktop
  ];

  programs.claude-code.preset = "work";

  programs.noctalia-shell.wallpaper.monitorDirectories = [
    {
      name = "DP-1";
      dimensions = "3840x1600";
      wallpaper = "wallhaven-gwweme_3840x1600.png";
    }
    {
      name = "eDP-1";
      dimensions = "1920x1080";
      wallpaper = "wallhaven-0q2877_1920x1080.png";
    }
  ];
  home.stateVersion = "25.11";
}
