{ pkgs, inputs, ... }:
{

  imports = with inputs.self.homeModules; [
    hyprland
    vscode
    firefox
  ];

  programs = {
    rofi = {
      enable = true;
    };
    hyprpanel = {
      enable = true;
    };
  };

  # hhttps://hyprpanel.com/getting_started/installation.html
  home.packages = with pkgs; [
    wireplumber
    libgtop
    bluez
    bluez-tools
    networkmanager
    wl-clipboard
    upower
    gvfs
  ];
}
