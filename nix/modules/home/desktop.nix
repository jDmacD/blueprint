{
  pkgs,
  inputs,
  lib,
  ...
}:
{

  imports = with inputs.self.homeModules; [
    hyprland
    vscode
    firefox
  ];

  programs = {
    rofi = {
      enable = true;
      theme = lib.mkForce "${pkgs.rofi}/share/rofi/themes/material.rasi";
    };
    hyprpanel = {
      enable = true;
    };
  };

  services = {
    hyprpaper = {
      enable = true;
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
  ];
}
