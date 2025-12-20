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

  # https://hyprpanel.com/getting_started/installation.html
  home.packages = with pkgs; [
    wireplumber
    libgtop
    bluez
    bluez-tools
    wl-clipboard
    gvfs
  ];
}
