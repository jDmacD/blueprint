{
  pkgs,
  inputs,
  lib,
  config,
  osConfig,
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
      # jdmacd/nix-overview (enabled in crann's desktop.toml): compare the
      # running system's configurationRevision (host-shared.nix) with
      # origin/main, counting only commits that can change this host.
      hostSettings.plugin_settings."jdmacd/nix-overview" = {
        flake_dir = "${config.home.homeDirectory}/blueprint";
        watch_paths = [
          "nix/hosts/${osConfig.networking.hostName}"
          "nix/modules"
          "nix/lib"
          "nix/packages"
          "flake.nix"
          "flake.lock"
        ];
      };
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
