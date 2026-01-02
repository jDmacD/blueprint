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
        wallpapers = [
          "eDP-1,${(import inputs.self.lib.wallpapers { inherit pkgs; }).default}" # surface
        ];
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
