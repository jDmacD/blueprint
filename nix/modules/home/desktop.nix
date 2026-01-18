{
  pkgs,
  inputs,
  lib,
  ...
}:
{

  imports = with inputs.self.homeModules; [
    hyprland
    hypridle
    noctalia
    vscode
    firefox
  ];

  programs = {
    rofi = {
      enable = false;
      theme = lib.mkForce "${pkgs.rofi}/share/rofi/themes/material.rasi";
    };
    hyprpanel = {
      enable = false;
    };
  };

  services = {
    hyprpaper = {
      enable = lib.mkDefault false;
      settings = {
        /*
          # These are set by stylix
          preload = [
            defaultWallpaper
          ];
          wallpapers = [
            "eDP-1,${defaultWallpaper}" # surface
          ];
        */
      };
    };
  };

  # https://hyprpanel.com/getting_started/installation.html
  home.packages = with pkgs; [
    wireplumber
    libgtop
    wl-clipboard
    gvfs
    vlc
    pinta
  ];
}
