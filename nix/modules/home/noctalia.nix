{
  inputs,
  lib,
  config,
  ...
}:
let
  wallPaperDirectory = "${config.home.homeDirectory}/Pictures/Wallpapers";
in
{
  imports = [
    inputs.noctalia.homeModules.default
  ];
  programs.noctalia-shell = {
    enable = true;
    settings = {
      # https://docs.noctalia.dev/getting-started/nixos/#config-ref
      bar = {
        backgroundOpacity = lib.mkForce 0.0;
        useSeparateOpacity = true;
      };
      location = {
        name = "Kilkenny";
      };
      general = {
        radiusRatio = 0;
        iRadiusRatio = 0;
        boxRadiusRatio = 0;
        screenRadiusRatio = 0;
      };
      ui = {
        panelsAttachedToBar = false;
      };
      appLauncher = {
        terminalCommand = "foot";
      };
      wallpaper = {
        enabled = true;
        directory = "${wallPaperDirectory}";
        enableMultiMonitorDirectories = true;
        monitorDirectories = [
          {
            directory = "${wallPaperDirectory}/3000x2000";
            name = "eDP-1";
            wallpaper = "${wallPaperDirectory}/3000x2000/wallhaven-n6kwqx_3000x2000.png";
          }
        ];
        recursiveSearch = true;
        randomEnabled = true;
      };
      dock = {
        enabled = false;
      };
    };
  };
}
