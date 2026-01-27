{ pkgs, ... }:
let
  hyprctl = "${pkgs.hyprland}/bin/hyprctl --instance 0";
in
{
  services.sunshine = {
    enable = true;
    autoStart = true;
    capSysAdmin = true;
    openFirewall = true;
    settings = {
      capture = "wlr";
    };
    # https://gist.github.com/Dregu/4c0dbb2582835e5d95e06c4bf7624e3b`
    applications = {
      apps = [
        {
          name = "Steam";
          prep-cmd = [
            # {
            #   do = "${hyprctl} output create headless SUNSHINE-1";
            #   undo = "${hyprctl} output remove SUNSHINE-1";
            # }
            {
              do = ''
                ${pkgs.bash}/bin/bash -c "export HYPRLAND_INSTANCE_SIGNATURE=$(ls -t $XDG_RUNTIME_DIR/hypr | head -1) && ${hyprctl} keyword monitor SUNSHINE-1,''${SUNSHINE_CLIENT_WIDTH}x''${SUNSHINE_CLIENT_HEIGHT}@''${SUNSHINE_CLIENT_FPS},auto,1"
              '';
              undo = ''
                ${pkgs.bash}/bin/bash -c "export HYPRLAND_INSTANCE_SIGNATURE=$(ls -t $XDG_RUNTIME_DIR/hypr | head -1) && ${hyprctl} keyword monitor SUNSHINE-1,disable"
              '';
            }
            {
              do = ''
                ${pkgs.bash}/bin/bash -c "export HYPRLAND_INSTANCE_SIGNATURE=$(ls -t $XDG_RUNTIME_DIR/hypr | head -1) && ${hyprctl} keyword monitor DP-1,disable"
              '';
              undo = ''
                ${pkgs.bash}/bin/bash -c "export HYPRLAND_INSTANCE_SIGNATURE=$(ls -t $XDG_RUNTIME_DIR/hypr | head -1) && ${hyprctl} reload"
              '';
            }
          ];
          exclude-global-prep-cmd = "false";
          auto-detach = "true";
        }
      ];

    };
  };

}
