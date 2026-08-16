{
  pkgs,
  inputs,
  lib,
  ...
}:
{

  imports = [
    inputs.crann.modules.homeManager.noctalia
    inputs.crann.modules.homeManager.vscode
    # wl-clipboard
    inputs.crann.modules.homeManager.desktop
    ./firefox.nix
  ];

  crann = {
    noctalia = {
      enable = true;
    };
    vscode = {
      enable = true;
    };
    desktop = {
      enable = true;
    };
  };

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
    gvfs
    vlc
    pinta
  ];
}
