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

  # https://hyprpanel.com/getting_started/installation.html
  home.packages = with pkgs; [
    wireplumber
    libgtop
    wl-clipboard
    gvfs
  ];
}
