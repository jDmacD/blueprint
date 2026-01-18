{
  inputs,
  lib,
  config,
  ...
}:
let
  cfg = config.programs.noctalia-shell;
  wallPaperDirectory = "${config.home.homeDirectory}/Pictures/Wallpapers";
in
{
  imports = [
    inputs.noctalia.homeModules.default
  ];

  options.programs.noctalia-shell = {
    wallpaper = {
      monitorDirectories = lib.mkOption {
        type = lib.types.listOf (
          lib.types.submodule {
            options = {
              name = lib.mkOption {
                type = lib.types.str;
                description = "Monitor name (e.g., eDP-1, HDMI-A-1)";
              };
              dimensions = lib.mkOption {
                type = lib.types.str;
                description = "Resolution dimensions (e.g., 3000x2000, 1920x1080)";
              };
              wallpaper = lib.mkOption {
                type = lib.types.str;
                description = "Wallpaper filename (e.g., wallhaven-n6kwqx_3000x2000.png)";
              };
            };
          }
        );
        default = [
          {
            name = "DP-1";
            dimensions = "1920x1080";
            wallpaper = "673780.jpg";
          }
        ];
        description = "Monitor-specific wallpaper directories";
      };
    };
  };

  config = {
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
          monitorDirectories = map (monitor: {
            name = monitor.name;
            directory = "${wallPaperDirectory}/${monitor.dimensions}";
            wallpaper = "${wallPaperDirectory}/${monitor.dimensions}/${monitor.wallpaper}";
          }) cfg.wallpaper.monitorDirectories;
          recursiveSearch = true;
          randomEnabled = true;
        };
        dock = {
          enabled = false;
        };
      };
    };
  };
}
